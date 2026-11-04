<#include "mcelements.ftl">
<#-- @formatter:off -->
if (world instanceof ServerLevel _serverLevel) {
	BlockEntity _be = _serverLevel.getBlockEntity(${toBlockPos(input$x,input$y,input$z)});
	if (_be instanceof Container _container && ${opt.toInt(input$slotid)} >= 0 && ${opt.toInt(input$slotid)} < _container.getContainerSize()) {
		_container.getItem(${opt.toInt(input$slotid)}).hurtAndBreak(${opt.toInt(input$amount)}, _serverLevel, null, _stkprov -> {});
	}
}
<#-- @formatter:on -->
