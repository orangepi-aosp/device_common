# Copyright 2022 Man Nguyen <nmman37@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

UBOOT_CROSS_COMPILE_PREFIX := $(TOP)/prebuilts/gcc/linux-x86/host/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

ATF_BLOB :=
ifeq ($(PRODUCT_PLATFORM),rk3399)
ATF_BLOB := $(realpath $(TOP))/vendor/rockchip/rkbin/bin/rk33/rk3399_bl31_v1.35.elf
endif

UBOOT_EXTRA_BUILD_ENV := \
	BL31=$(ATF_BLOB)

include $(TOP)/bootable/u-boot/AndroidUBoot.mk

uboot: $(UBOOT_CROSS_COMPILE_PREFIX)gcc $(ATF_BLOB)

.PHONY: uboot_sd
uboot_sd: PRIVATE_TARGET := $(PRODUCT_OUT)/u-boot-sd.img
uboot_sd: uboot
	$(hide) echo "Creating U-Boot SD image..."
	dd if=$(UBOOT_OUT)/u-boot-rockchip.bin of=$(PRIVATE_TARGET) seek=64 conv=notrunc
	$(hide) echo "Written to $(PRIVATE_TARGET)"

.PHONY: uboot_full
uboot_full: uboot_sd

# Include uboot to default target
droidcore-unbundled: uboot_full
