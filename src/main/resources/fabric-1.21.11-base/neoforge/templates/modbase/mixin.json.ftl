<#-- A fragment can hold several mixin names, one per line -->
<#assign mixins = []>
<#list fragments.mixin as fragment>
  <#list fragment?split("\n") as line>
    <#assign mixinName = line?trim>
    <#if mixinName?has_content && !mixins?seq_contains(mixinName)>
      <#assign mixins = mixins + [mixinName]>
    </#if>
  </#list>
</#list>
{
  "required": true,
  "package": "${package}.mixin",
  "compatibilityLevel": "JAVA_25",
  "mixins": [
	<#list mixins as mixin>"${mixin}"<#sep>,</#list>
  ],
  "client": [
  ],
  "injectors": {
    "defaultRequire": 1
  },
  "minVersion": "0.8.4"
}