private static ItemStack itemFromBlockInventory(LevelAccessor world, BlockPos pos, int slot) {
	if (world.getBlockEntity(pos) instanceof Container container && slot >= 0 && slot < container.getContainerSize()) {
		return container.getItem(slot);
	}
	return ItemStack.EMPTY;
}
