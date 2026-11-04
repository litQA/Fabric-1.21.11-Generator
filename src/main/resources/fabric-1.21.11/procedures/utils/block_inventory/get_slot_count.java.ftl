private static int getBlockInventorySlotCount(LevelAccessor world, BlockPos pos) {
	if (world.getBlockEntity(pos) instanceof Container container) {
		return container.getContainerSize();
	}
	return 0;
}
