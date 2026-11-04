<#-- @formatter:off -->
/*
 *	MCreator note: This file will be REGENERATED on each build.
 */

package ${package}.init;

/**
 * Session-local entity NBT storage used by the entity NBT procedure blocks.
 *
 * <p>Fabric has no equivalent of NeoForge's persistent entity data. This helper keeps a tag per
 * entity UUID for the lifetime of the process. Values are not written to the world save; this is
 * documented as a known limitation of the Fabric 1.21.11 generator.
 */
public class ${JavaModName}EntityNbt {
	private static final Map<UUID, CompoundTag> DATA = new ConcurrentHashMap<>();

	public static CompoundTag get(Entity entity) {
		return DATA.computeIfAbsent(entity.getUUID(), uuid -> new CompoundTag());
	}

	public static void setDouble(Entity entity, String tag, double value) {
		get(entity).putDouble(tag, value);
	}

	public static double getDouble(Entity entity, String tag, double fallback) {
		CompoundTag data = get(entity);
		return data.contains(tag) ? data.getDoubleOr(tag, fallback) : fallback;
	}
}
<#-- @formatter:on -->
