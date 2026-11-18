<#--
 # This file is part of Fabric-Generator-MCreator.
 # Copyright (C) 2012-2020, Pylo
 # Copyright (C) 2020-2026, Pylo, opensource contributors
 # Copyright (C) 2020-2026, Goldorion, opensource contributors
 #
 # Fabric-Generator-MCreator is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # Fabric-Generator-MCreator is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with Fabric-Generator-MCreator. If not, see <https://www.gnu.org/licenses/>.
-->

<#-- @formatter:off -->
<#include "../mcitems.ftl">

package ${package}.world.teleporter;

import org.jetbrains.annotations.Nullable;

import org.apache.commons.lang3.mutable.MutableInt;

import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.NetherPortalBlock;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.entity.EntityDimensions;
import net.minecraft.world.entity.Entity;
import net.minecraft.util.Mth;
import net.minecraft.util.BlockUtil;
import net.minecraft.tags.BlockTags;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.core.Direction;
import net.minecraft.core.BlockPos;

import ${package}.init.${JavaModName}Blocks;

import java.util.function.Predicate;
import java.util.Optional;

public class ${name}PortalShape {
	private static final int MIN_WIDTH = 2;
	public static final int MAX_WIDTH = 21;
	private static final int MIN_HEIGHT = 3;
	public static final int MAX_HEIGHT = 21;
	private static final BlockBehaviour.StatePredicate FRAME = (blockState, blockGetter, blockPos) -> blockState.is(${mappedBlockToBlock(data.portalFrame)});

	private static final float SAFE_TRAVEL_MAX_ENTITY_XY = 4.0f;
	private static final double SAFE_TRAVEL_MAX_VERTICAL_DELTA = 1.0;
	private final Direction.Axis axis;
	private final Direction rightDir;
	private final int numPortalBlocks;
	private final BlockPos bottomLeft;
	private final int height;
	private final int width;

	public ${name}PortalShape(Direction.Axis axis, int i, Direction direction, BlockPos blockPos, int j, int k) {
		this.axis = axis;
		this.numPortalBlocks = i;
		this.rightDir = direction;
		this.bottomLeft = blockPos;
		this.width = j;
		this.height = k;
	}

	public static Optional<${name}PortalShape> findEmptyPortalShape(LevelAccessor levelAccessor, BlockPos blockPos, Direction.Axis axis) {
		return findPortalShape(levelAccessor, blockPos, portalShape -> portalShape.isValid() && portalShape.numPortalBlocks == 0, axis);
	}

	public static Optional<${name}PortalShape> findPortalShape(LevelAccessor levelAccessor, BlockPos blockPos, Predicate<${name}PortalShape> predicate, Direction.Axis axis) {
		Optional<${name}PortalShape> optional = Optional.of(findAnyShape(levelAccessor, blockPos, axis)).filter(predicate);
		if (optional.isPresent()) {
			return optional;
		}
		Direction.Axis axis2 = axis == Direction.Axis.X ? Direction.Axis.Z : Direction.Axis.X;
		return Optional.of(findAnyShape(levelAccessor, blockPos, axis2)).filter(predicate);
	}

	public static ${name}PortalShape findAnyShape(BlockGetter blockGetter, BlockPos blockPos, Direction.Axis axis) {
		Direction direction = axis == Direction.Axis.X ? Direction.WEST : Direction.SOUTH;
		BlockPos blockPos2 = calculateBottomLeft(blockGetter, direction, blockPos);
		if (blockPos2 == null) {
			return new ${name}PortalShape(axis, 0, direction, blockPos, 0, 0);
		}
		int i = calculateWidth(blockGetter, blockPos2, direction);
		if (i == 0) {
			return new ${name}PortalShape(axis, 0, direction, blockPos2, 0, 0);
		}
		MutableInt mutableInt = new MutableInt();
		int j = calculateHeight(blockGetter, blockPos2, direction, i, mutableInt);
		return new ${name}PortalShape(axis, mutableInt.intValue(), direction, blockPos2, i, j);
	}

	private static @Nullable BlockPos calculateBottomLeft(BlockGetter blockGetter, Direction direction, BlockPos blockPos) {
		int i = Math.max(blockGetter.getMinY(), blockPos.getY() - 21);
		while (blockPos.getY() > i && isEmpty(blockGetter.getBlockState(blockPos.below()))) {
			blockPos = blockPos.below();
		}
		Direction direction2 = direction.getOpposite();
		int j = getDistanceUntilEdgeAboveFrame(blockGetter, blockPos, direction2) - 1;
		if (j < 0) {
			return null;
		}
		return blockPos.relative(direction2, j);
	}

	private static int calculateWidth(BlockGetter blockGetter, BlockPos blockPos, Direction direction) {
		int i = getDistanceUntilEdgeAboveFrame(blockGetter, blockPos, direction);
		if (i < 2 || i > 21) {
			return 0;
		}
		return i;
	}

	private static int getDistanceUntilEdgeAboveFrame(BlockGetter blockGetter, BlockPos blockPos, Direction direction) {
		BlockPos.MutableBlockPos mutableBlockPos = new BlockPos.MutableBlockPos();
		for (int i = 0; i <= 21; ++i) {
			mutableBlockPos.set(blockPos).move(direction, i);
			BlockState blockState = blockGetter.getBlockState(mutableBlockPos);
			if (!isEmpty(blockState)) {
				if (!FRAME.test(blockState, blockGetter, mutableBlockPos))
					break;
				return i;
			}
			BlockState blockState2 = blockGetter.getBlockState(mutableBlockPos.move(Direction.DOWN));
			if (!FRAME.test(blockState2, blockGetter, mutableBlockPos))
				break;
		}
		return 0;
	}

	private static int calculateHeight(BlockGetter blockGetter, BlockPos blockPos, Direction direction, int i, MutableInt mutableInt) {
		BlockPos.MutableBlockPos mutableBlockPos = new BlockPos.MutableBlockPos();
		int j = getDistanceUntilTop(blockGetter, blockPos, direction, mutableBlockPos, i, mutableInt);
		if (j < 3 || j > 21 || !hasTopFrame(blockGetter, blockPos, direction, mutableBlockPos, i, j)) {
			return 0;
		}
		return j;
	}

	private static boolean hasTopFrame(BlockGetter blockGetter, BlockPos blockPos, Direction direction, BlockPos.MutableBlockPos mutableBlockPos, int i, int j) {
		for (int k = 0; k < i; ++k) {
			BlockPos.MutableBlockPos mutableBlockPos2 = mutableBlockPos.set(blockPos).move(Direction.UP, j).move(direction, k);
			if (FRAME.test(blockGetter.getBlockState(mutableBlockPos2), blockGetter, mutableBlockPos2))
				continue;
			return false;
		}
		return true;
	}

	private static int getDistanceUntilTop(BlockGetter blockGetter, BlockPos blockPos, Direction direction, BlockPos.MutableBlockPos mutableBlockPos, int i, MutableInt mutableInt) {
		for (int j = 0; j < 21; ++j) {
			mutableBlockPos.set(blockPos).move(Direction.UP, j).move(direction, -1);
			if (!FRAME.test(blockGetter.getBlockState(mutableBlockPos), blockGetter, mutableBlockPos)) {
				return j;
			}
			mutableBlockPos.set(blockPos).move(Direction.UP, j).move(direction, i);
			if (!FRAME.test(blockGetter.getBlockState(mutableBlockPos), blockGetter, mutableBlockPos)) {
				return j;
			}
			for (int k = 0; k < i; ++k) {
				mutableBlockPos.set(blockPos).move(Direction.UP, j).move(direction, k);
				BlockState blockState = blockGetter.getBlockState(mutableBlockPos);
				if (!isEmpty(blockState)) {
					return j;
				}
				if (!blockState.is(${JavaModName}Blocks.${REGISTRYNAME}_PORTAL))
					continue;

				mutableInt.increment();
			}
		}
		return 21;
	}

	private static boolean isEmpty(BlockState blockState) {
		return blockState.isAir() || blockState.is(BlockTags.FIRE) || blockState.is(${JavaModName}Blocks.${REGISTRYNAME}_PORTAL);
	}

	public boolean isValid() {
		return this.width >= 2 && this.width <= 21 && this.height >= 3 && this.height <= 21;
	}

	public void createPortalBlocks(LevelAccessor levelAccessor) {
		BlockState blockState = (BlockState) ${JavaModName}Blocks.${REGISTRYNAME}_PORTAL.defaultBlockState().setValue(NetherPortalBlock.AXIS, this.axis);
		BlockPos.betweenClosed(this.bottomLeft, this.bottomLeft.relative(Direction.UP, this.height - 1).relative(this.rightDir, this.width - 1)).forEach(blockPos -> levelAccessor.setBlock((BlockPos) blockPos, blockState, 18));
	}

	public boolean isComplete() {
		return this.isValid() && this.numPortalBlocks == this.width * this.height;
	}

	public static Vec3 getRelativePosition(BlockUtil.FoundRectangle foundRectangle, Direction.Axis axis, Vec3 vec3, EntityDimensions entityDimensions) {
		Direction.Axis axis2;
		double g;
		double f;
		double d = (double) foundRectangle.axis1Size - (double) entityDimensions.width();
		double e = (double) foundRectangle.axis2Size - (double) entityDimensions.height();
		BlockPos blockPos = foundRectangle.minCorner;
		if (d > 0.0) {
			f = (double) blockPos.get(axis) + (double) entityDimensions.width() / 2.0;
			g = Mth.clamp(Mth.inverseLerp(vec3.get(axis) - f, 0.0, d), 0.0, 1.0);
		} else {
			g = 0.5;
		}
		if (e > 0.0) {
			axis2 = Direction.Axis.Y;
			f = Mth.clamp(Mth.inverseLerp(vec3.get(axis2) - (double) blockPos.get(axis2), 0.0, e), 0.0, 1.0);
		} else {
			f = 0.0;
		}
		axis2 = axis == Direction.Axis.X ? Direction.Axis.Z : Direction.Axis.X;
		double h = vec3.get(axis2) - ((double) blockPos.get(axis2) + 0.5);
		return new Vec3(g, f, h);
	}

	public static Vec3 findCollisionFreePosition(Vec3 vec32, ServerLevel serverLevel, Entity entity, EntityDimensions entityDimensions) {
		if (entityDimensions.width() > 4.0f || entityDimensions.height() > 4.0f) {
			return vec32;
		}
		double d = (double) entityDimensions.height() / 2.0;
		Vec3 vec322 = vec32.add(0.0, d, 0.0);
VoxelShape voxelShape = Shapes.create(AABB.ofSize(vec322, entityDimensions.width(), 0.0, entityDimensions.width()).expandTowards(0.0, 1.0, 0.0).inflate(1.0E-6));
		Optional<Vec3> optional = serverLevel.findFreePosition(entity, voxelShape, vec322, entityDimensions.width(), entityDimensions.height(), entityDimensions.width());
		Optional<Vec3> optional2 = optional.map(v -> v.subtract(0.0, d, 0.0));

		return optional2.orElse(vec32);

}
}
<#-- @formatter:on -->
