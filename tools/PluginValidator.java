import freemarker.template.Configuration;
import freemarker.template.Template;
import org.snakeyaml.engine.v2.api.Load;
import org.snakeyaml.engine.v2.api.LoadSettings;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * Offline static validator for the Fabric 1.21.11 generator resources.
 *
 * <p>Checks performed:
 * <ul>
 *   <li>every FreeMarker template parses with the FreeMarker 2.3.35 engine shipped by MCreator;</li>
 *   <li>every YAML document parses with SnakeYAML Engine 3.2 (the parser used by MCreator 2026.3);</li>
 *   <li>every {@code <#include>} and {@code <@addTemplate>} target exists in the plugin tree;</li>
 *   <li>every {@code template:} reference from a definition/generator file resolves to a file;</li>
 *   <li>obfuscated-1.21.11 build invariants: Java 21 class files, official Mojang mappings,
 *       Loom remapping plugin, data pack format 94.1, Fabric Loader 0.20.1.</li>
 * </ul>
 *
 * <p>Exit code 0 means no errors were found. Warnings are reported but do not fail the run.
 */
public final class PluginValidator {

    private static final Pattern INCLUDE = Pattern.compile("<#include\\s+\"([^\"]+)\"");
    private static final Pattern ADD_TEMPLATE = Pattern.compile("<@addTemplate\\s+file=\"([^\"]+)\"");
    private static final Pattern TEMPLATE_REF = Pattern.compile("(?m)^\\s*(?:-\\s*)?template:\\s*([^\\s#]+)");

    private static final String GENERATOR_DIR = "fabric-1.21.11";
    private static final String BASE_DIR = "fabric-1.21.11-base";

    private final Path resources;
    private final List<String> errors = new ArrayList<>();
    private final List<String> warnings = new ArrayList<>();
    private final Set<String> allFiles = new TreeSet<>();
    private int ftlCount;
    private int yamlCount;
    private int includeCount;
    private int templateRefCount;

    private PluginValidator(Path resources) {
        this.resources = resources;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("usage: PluginValidator <src/main/resources>");
            System.exit(2);
        }
        PluginValidator validator = new PluginValidator(Path.of(args[0]).toAbsolutePath().normalize());
        boolean ok = validator.run();
        System.out.println();
        System.out.println("=== Generator static validation ===");
        System.out.println("templates parsed : " + validator.ftlCount);
        System.out.println("yaml documents   : " + validator.yamlCount);
        System.out.println("includes checked : " + validator.includeCount);
        System.out.println("template refs    : " + validator.templateRefCount);
        System.out.println("resources        : " + validator.allFiles.size());
        if (!validator.warnings.isEmpty()) {
            System.out.println("warnings         : " + validator.warnings.size());
            validator.warnings.stream().limit(20).forEach(w -> System.out.println("  WARN " + w));
        }
        if (!validator.errors.isEmpty()) {
            System.out.println("errors           : " + validator.errors.size());
            validator.errors.stream().limit(80).forEach(e -> System.out.println("  FAIL " + e));
            System.out.println("RESULT: FAILED");
            System.exit(1);
        }
        System.out.println("RESULT: OK");
    }

    private boolean run() throws IOException {
        if (!Files.isDirectory(resources)) {
            errors.add("resources directory not found: " + resources);
            return false;
        }
        try (Stream<Path> stream = Files.walk(resources)) {
            stream.filter(Files::isRegularFile).forEach(p ->
                    allFiles.add(resources.relativize(p).toString().replace('\\', '/')));
        }

        Configuration cfg = new Configuration(Configuration.VERSION_2_3_31);
        cfg.setDefaultEncoding("UTF-8");
        cfg.setLogTemplateExceptions(false);

        LoadSettings yamlSettings = LoadSettings.builder().setLabel("generator").build();
        Load yaml = new Load(yamlSettings);

        for (String relative : allFiles) {
            Path file = resources.resolve(relative);
            if (relative.endsWith(".ftl")) {
                ftlCount++;
                validateTemplate(cfg, file, relative);
            } else if (relative.endsWith(".yaml") || relative.endsWith(".yml")) {
                yamlCount++;
                validateYaml(yaml, file, relative);
            }
            if (relative.endsWith(".yaml") || relative.endsWith(".yml")) {
                validateTemplateReferences(file, relative);
            }
        }
        validateBuildInvariants();
        validateGeneratorLayout();
        return errors.isEmpty();
    }

    private void validateTemplate(Configuration cfg, Path file, String relative) {
        try {
            String text = Files.readString(file, StandardCharsets.UTF_8);
            new Template(relative, new StringReader(text), cfg);
            for (Pattern p : List.of(INCLUDE, ADD_TEMPLATE)) {
                Matcher m = p.matcher(text);
                while (m.find()) {
                    includeCount++;
                    String target = m.group(1);
                    if (!resolveInclude(file, target)) {
                        errors.add(relative + ": unresolved template include '" + target + "'");
                    }
                }
            }
        } catch (Exception e) {
            errors.add(relative + ": FreeMarker parse error: " + firstLine(e.getMessage()));
        }
    }

    /**
     * MCreator resolves template includes through the generator template loader, which exposes the
     * {@code templates/} and {@code utils/} folders of every generator in the import chain. The
     * resolution order below mirrors that behaviour: path relative to the including file first,
     * then the well-known generator folders, then a basename lookup for bare includes.
     */
    private boolean resolveInclude(Path includingFile, String target) {
        String includeRel = resources.relativize(includingFile).toString().replace('\\', '/');
        String includeDir = includeRel.contains("/") ? includeRel.substring(0, includeRel.lastIndexOf('/')) : "";

        List<String> candidates = new ArrayList<>();
        Path relativeToFile = includingFile.getParent().resolve(target).normalize();
        if (Files.isRegularFile(relativeToFile)) {
            return true;
        }
        // MCreator renders templates by name relative to the generator template root
        // ("templates/block/block.java.ftl" is addressed as "block/block.java.ftl"), so a
        // "../mcitems.ftl" include resolves to the generator template/utils root rather than
        // to a physical parent of the file. Reconstruct that view here.
        String perLayerDir = includeDir;
        for (String prefix : List.of(GENERATOR_DIR + "/templates", GENERATOR_DIR + "/procedures",
                GENERATOR_DIR + "/features", GENERATOR_DIR + "/triggers", BASE_DIR + "/datapack/templates",
                BASE_DIR + "/neoforge/templates", BASE_DIR + "/neoforge/procedures")) {
            if (includeDir.startsWith(prefix)) {
                perLayerDir = includeDir.substring(prefix.length());
                if (perLayerDir.startsWith("/")) {
                    perLayerDir = perLayerDir.substring(1);
                }
                break;
            }
        }
        String templateRelative = perLayerDir.isEmpty() ? target
                : Path.of(perLayerDir).resolve(target).normalize().toString().replace('\\', '/');

        List<String> layerRoots = List.of(GENERATOR_DIR, BASE_DIR + "/datapack", BASE_DIR + "/neoforge");
        for (String root : layerRoots) {
            for (String sub : List.of("templates", "utils", "procedures", "features", "jsontriggers", "aitasks",
                    "triggers", "cmdargs", "variables", "")) {
                Path candidate = resources.resolve(root + (sub.isEmpty() ? "" : "/" + sub))
                        .resolve(templateRelative).normalize();
                if (Files.isRegularFile(candidate)) {
                    return true;
                }
                candidate = resources.resolve(root + (sub.isEmpty() ? "" : "/" + sub))
                        .resolve(target).normalize();
                if (Files.isRegularFile(candidate)) {
                    return true;
                }
            }
        }
        // Last resort: any file with the same trailing path inside the plugin tree.
        String suffix = "/" + target.replace('\\', '/');
        return allFiles.stream().anyMatch(f -> f.endsWith(suffix));
    }

    private void validateYaml(Load yaml, Path file, String relative) {
        try {
            Object loaded = yaml.loadFromString(Files.readString(file, StandardCharsets.UTF_8));
            if (loaded == null) {
                warnings.add(relative + ": empty YAML document");
            } else if (!(loaded instanceof Map)) {
                errors.add(relative + ": top-level YAML document is not a mapping");
            }
        } catch (Exception e) {
            errors.add(relative + ": YAML parse error: " + firstLine(e.getMessage()));
        }
    }

    private void validateTemplateReferences(Path file, String relative) {
        try {
            String text = Files.readString(file, StandardCharsets.UTF_8);
            Matcher m = TEMPLATE_REF.matcher(text);
            while (m.find()) {
                String template = m.group(1).trim();
                if (template.isEmpty() || template.startsWith("@")) {
                    continue;
                }
                templateRefCount++;
                boolean found = allFiles.stream().anyMatch(f -> f.equals(template) || f.endsWith("/" + template));
                if (!found) {
                    errors.add(relative + ": template reference '" + template + "' does not exist");
                }
            }
        } catch (IOException e) {
            errors.add(relative + ": cannot read: " + e.getMessage());
        }
    }

    private void validateGeneratorLayout() {
        List<String> generators = allFiles.stream().filter(f -> f.endsWith("generator.yaml")).toList();
        if (generators.size() != 1) {
            errors.add("expected exactly one generator.yaml, found " + generators);
        } else if (!generators.get(0).equals(GENERATOR_DIR + "/generator.yaml")) {
            errors.add("generator.yaml must be at " + GENERATOR_DIR + "/generator.yaml, found " + generators.get(0));
        }
        for (String base : List.of(BASE_DIR + "/datapack", BASE_DIR + "/neoforge")) {
            if (!allFiles.stream().anyMatch(f -> f.startsWith(base + "/"))) {
                errors.add("base layer missing: " + base);
            }
        }
        if (allFiles.stream().anyMatch(f -> f.startsWith(BASE_DIR) && f.endsWith("generator.yaml"))) {
            errors.add("base layers must not contain generator.yaml");
        }
    }

    private void validateBuildInvariants() {
        String modJson = read(GENERATOR_DIR + "/templates/modbase/fabric.mod.json.ftl");
        if (modJson == null) {
            errors.add("missing fabric.mod.json template");
        } else {
            if (!modJson.contains("\"fabricloader\": \">=0.20.1\"")) {
                errors.add("fabric.mod.json must require fabricloader >=0.20.1");
            }
            if (!modJson.contains("\"java\": \">=21\"")) {
                errors.add("fabric.mod.json must require java >=21 (Minecraft 1.21.11 runtime)");
            }
        }

        String mixin = read(GENERATOR_DIR + "/templates/modbase/mixin.json.ftl");
        if (mixin == null) {
            errors.add("missing mixin.json template");
        } else if (!mixin.contains("JAVA_21")) {
            errors.add("mixin.json compatibilityLevel must be JAVA_21 for Minecraft 1.21.11");
        }

        String accessWidener = read(GENERATOR_DIR + "/templates/modbase/accesswidener.ftl");
        if (accessWidener == null) {
            errors.add("missing access widener / class tweaker template");
        } else {
            String header = accessWidener.lines().filter(l -> !l.trim().isEmpty()).findFirst().orElse("").trim();
            if (!header.equals("classTweaker v1 named")) {
                errors.add("class tweaker header must be 'classTweaker v1 named' for obfuscated 1.21.11 (found '"
                        + header + "'); 'official' triggers Loom's 'Namespace mismatch, expected named got official'");
            }
        }

        String workspace = read(GENERATOR_DIR + "/workspacebase/build.gradle");
        if (workspace == null) {
            errors.add("missing workspacebase/build.gradle");
        } else {
            if (!workspace.contains("net.fabricmc.fabric-loom-remap")) {
                errors.add("workspace build must use the Loom remapping plugin for obfuscated 1.21.11");
            }
            if (!workspace.contains("loom.officialMojangMappings()")) {
                errors.add("workspace build must declare official Mojang mappings");
            }
            if (!workspace.contains("fabric-loader:0.20.1")) {
                errors.add("workspace build must pin Fabric Loader 0.20.1");
            }
            if (!workspace.contains("release = 21")) {
                errors.add("workspace build must target Java 21 bytecode");
            }
            if (!workspace.contains("classTweaker v1 official") || !workspace.contains("classTweaker v1 named")) {
                errors.add("workspace build must keep the class tweaker migration guard ('official' -> 'named')");
            }
        }

        String packMeta = read(BASE_DIR + "/datapack/templates/pack.mcmeta.ftl");
        if (packMeta == null) {
            errors.add("missing pack.mcmeta template");
        } else if (!packMeta.contains("94.1")) {
            errors.add("pack.mcmeta must use data pack format 94.1 for Minecraft 1.21.11");
        }

        String generator = read(GENERATOR_DIR + "/generator.yaml");
        if (generator != null) {
            if (!generator.contains("buildfileversion: 0.141.6")) {
                errors.add("generator.yaml must pin Fabric API 0.141.6");
            }
            if (!generator.contains("fabric-1.21.11-base/datapack")
                    || !generator.contains("fabric-1.21.11-base/neoforge")) {
                errors.add("generator.yaml must import the namespaced base layers");
            }
        }

        // Project decisions: CC BY-NC 4.0 licence with upstream attribution, and an offline
        // Gradle distribution URL with the public URL kept commented.
        String license = read("LICENSE");
        if (license == null) {
            errors.add("missing LICENSE");
        } else if (!license.contains("Attribution-NonCommercial 4.0 International")) {
            errors.add("LICENSE must be the CC BY-NC 4.0 text selected for this project");
        }
        String notice = read("NOTICE.md");
        if (notice == null) {
            errors.add("missing NOTICE.md (upstream attribution is required)");
        } else if (!notice.contains("Fabric-Generator-MCreator") || !notice.contains("MCreator")) {
            errors.add("NOTICE.md must attribute Fabric-Generator-MCreator and MCreator");
        }

        String wrapper = read(GENERATOR_DIR + "/workspacebase/gradle/wrapper/gradle-wrapper.properties");
        if (wrapper == null) {
            errors.add("missing workspace gradle-wrapper.properties");
        } else {
            String activeDistribution = wrapper.lines()
                    .filter(line -> line.startsWith("distributionUrl="))
                    .findFirst()
                    .orElse("");
            if (!activeDistribution.equals("distributionUrl=https\\://services.gradle.org/distributions/gradle-9.8.0-bin.zip")) {
                errors.add("workspace wrapper must use the public Gradle distribution URL");
            }
            if (wrapper.contains("file\\:///")) {
                errors.add("workspace wrapper must not contain a local file distribution URL");
            }
            if (!wrapper.contains("validateDistributionUrl=true")) {
                errors.add("workspace wrapper must validate the public Gradle distribution URL");
            }
        }

        validateWorkspaceBuildTemplate();
        validateNoRemovedApiUsage();
    }

    /**
     * The template baseline is Minecraft 26.1.2; a handful of its APIs were introduced after
     * 1.21.11 and do not exist in the target game. Detect the ones that already caused real
     * compilation failures so they cannot be reintroduced silently.
     */
    private void validateNoRemovedApiUsage() {
        Map<String, String> forbidden = new java.util.LinkedHashMap<>();
        forbidden.put("GuiGraphicsExtractor", "1.21.11 uses GuiGraphics (Screen#render/renderBackground/renderLabels)");
        forbidden.put("ContainerInput", "1.21.11 uses ClickType for AbstractContainerMenu#clicked");
        forbidden.put("ItemStackTemplate", "1.21.11 has no ItemStackTemplate; use ItemStack / Item.Properties#craftRemainder");
        forbidden.put(".postProcess(", "1.21.11 uses BlockBehaviour.Properties#hasPostProcess");
        forbidden.put("getLightDampening", "1.21.11 uses getLightBlock(BlockState)");
        forbidden.put("getLightCoords", "1.21.11 uses getLightColor(float)");
        forbidden.put("CreativeModeTabEvents", "1.21.11 Fabric API uses ItemGroupEvents.modifyEntriesEvent");
        forbidden.put("ParticleProviderRegistry", "1.21.11 Fabric API uses ParticleFactoryRegistry");
        forbidden.put("KeyMappingHelper", "1.21.11 Fabric API uses KeyBindingHelper.registerKeyBinding");
        forbidden.put("serverboundPlay(", "0.141.6 uses PayloadTypeRegistry.playC2S()");
        forbidden.put("clientboundPlay(", "0.141.6 uses PayloadTypeRegistry.playS2C()");
        forbidden.put("FabricPotionBrewingBuilder", "0.141.6 uses FabricBrewingRecipeRegistryBuilder");
        forbidden.put("types[", "MCreator 2026.3 always exposes type keys; use types.<name>?has_content");
        forbidden.put("FluidRenderingRegistry", "0.141.6 uses FluidRenderHandlerRegistry + SimpleFluidRenderHandler");
        forbidden.put("FuelValueEvents", "0.141.6 uses FuelRegistryEvents");
        forbidden.put("ServerLevelEvents", "0.141.6 uses ServerWorldEvents");
        forbidden.put("ServerEntityLevelChangeEvents", "0.141.6 uses ServerEntityWorldChangeEvents");
        forbidden.put("END_LEVEL_TICK", "0.141.6 uses END_WORLD_TICK");
        forbidden.put("delayedComponent", "1.21.11 Item.Properties uses component(...)");
        forbidden.put("HUMANOID_BABY", "1.21.11 EquipmentClientInfo.LayerType has no baby layer");
        forbidden.put("protected void renderWidget", "1.21.11 buttons use renderContents(...); renderWidget is final");
        forbidden.put("protected void renderWidget", "slider renderWidget must be public, not protected");
        forbidden.put("PlayerLookup.level(", "0.141.6 uses PlayerLookup.world(ServerLevel)");
        for (String relative : allFiles) {
            if (!relative.startsWith(GENERATOR_DIR + "/") || !relative.endsWith(".ftl")) {
                continue;
            }
            String text;
            try {
                text = Files.readString(resources.resolve(relative), StandardCharsets.UTF_8);
            } catch (IOException e) {
                errors.add(relative + ": cannot read: " + e.getMessage());
                continue;
            }
            for (Map.Entry<String, String> entry : forbidden.entrySet()) {
                if (text.contains(entry.getKey())) {
                    errors.add(relative + ": uses API not available in 1.21.11: '" + entry.getKey()
                            + "' (" + entry.getValue() + ")");
                }
            }
        }
    }

    /**
     * MCreator preprocesses every workspace-base file with FreeMarker before copying it into the
     * workspace (WorkspaceGeneratorSetup#setupWorkspaceBase). A Groovy GString such as
     * {@code "${tweaker.name}"} in build.gradle is therefore evaluated as FreeMarker at setup time
     * and aborts the whole base copy. Render the template with the variables MCreator provides to
     * catch that class of defect offline.
     */
    private void validateWorkspaceBuildTemplate() {
        String text = read(GENERATOR_DIR + "/workspacebase/build.gradle");
        if (text == null) {
            return;
        }
        try {
            Configuration cfg = new Configuration(Configuration.VERSION_2_3_31);
            Template template = new Template("workspacebase/build.gradle", new StringReader(text), cfg);
            Map<String, Object> model = new HashMap<>();
            model.put("modid", "testmod");
            model.put("generator", new DummyGenerator());
            template.process(model, new StringWriter());
        } catch (Exception e) {
            errors.add("workspacebase/build.gradle must be FreeMarker-safe (MCreator renders it at workspace setup): "
                    + firstLine(e.getMessage()));
        }
    }

    /** Minimal stand-in for the generator object exposed to workspace-base templates. */
    public static final class DummyGenerator {
        public String getGeneratorMinecraftVersion() {
            return "1.21.11";
        }

        public String getGeneratorBuildFileVersion() {
            return "0.141.6";
        }
    }

    private String read(String relative) {
        Path p = resources.resolve(relative);
        try {
            return Files.isRegularFile(p) ? Files.readString(p, StandardCharsets.UTF_8) : null;
        } catch (IOException e) {
            errors.add(relative + ": cannot read: " + e.getMessage());
            return null;
        }
    }

    private static String firstLine(String message) {
        if (message == null) {
            return "unknown error";
        }
        int idx = message.indexOf('\n');
        return idx < 0 ? message : message.substring(0, idx);
    }
}
