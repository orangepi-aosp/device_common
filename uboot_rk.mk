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

TOP_ABS := $(realpath $(TOP))
RK_BIN_TOP_ABS := $(TOP_ABS)/vendor/rockchip/rkbin

RK_MINILOADER :=
RK_DDR_BIN :=
RK_TRUST_INI :=

ATF_BLOB :=

ifeq ($(PRODUCT_PLATFORM),rk3399)
ATF_BLOB := $(RK_BIN_TOP_ABS)/bin/rk33/rk3399_bl31_v1.35.elf
RK_MINILOADER := bin/rk33/rk3399_miniloader_v1.26.bin
RK_DDR_BIN := bin/rk33/rk3399_ddr_933MHz_v1.27.bin
RK_TRUST_INI := RKTRUST/RK3399TRUST.ini
UBOOT_SYS_TEXT_BASE := 0x00200000
else
$(error Unsupported platform $(PRODUCT_PLATFORM))
endif

UBOOT_EXTRA_BUILD_ENV := \
	BL31=$(ATF_BLOB)

include $(TOP)/bootable/u-boot/AndroidUBoot.mk

uboot: $(UBOOT_CROSS_COMPILE_PREFIX)gcc $(ATF_BLOB)

uboot_rk_deps :=
ifeq ($(UBOOT_ROCKCHIP_SPL),true)
uboot_rk_deps += $(RK_BIN_TOP_ABS)/$(RK_MINILOADER) \
				 $(RK_BIN_TOP_ABS)/$(RK_DDR_BIN) \
				 $(RK_BIN_TOP_ABS)/$(RK_TRUST_INI)
endif

.PHONY: uboot_rk
uboot_rk: PRIVATE_TARGET := $(PRODUCT_OUT)/u-boot-rockchip.img
uboot_rk: uboot $(uboot_rk_deps)
	$(hide) echo "Creating U-Boot image..."
ifeq ($(UBOOT_ROCKCHIP_SPL),true)
	mkdir -p $(UBOOT_OUT)/rktmp

	$(hide) echo "Making idbloader.img..."
	cd $(RK_BIN_TOP_ABS) && tools/mkimage -n $(PRODUCT_PLATFORM) -T rksd -d $(RK_DDR_BIN) \
		$(TOP_ABS)/$(UBOOT_OUT)/rktmp/idbloader.img
	cat $(RK_BIN_TOP_ABS)/$(RK_MINILOADER) >> $(UBOOT_OUT)/rktmp/idbloader.img

	$(hide) echo "Making uboot.img..."
	cd $(RK_BIN_TOP_ABS) && tools/loaderimage --pack --uboot $(TOP_ABS)/$(UBOOT_OUT)/u-boot.bin \
		$(TOP_ABS)/$(UBOOT_OUT)/rktmp/uboot.img $(UBOOT_SYS_TEXT_BASE)

	$(hide) echo "Making trust.img..."
	cd $(RK_BIN_TOP_ABS) && tools/trust_merger $(RK_TRUST_INI)
	mv $(RK_BIN_TOP_ABS)/trust.img $(TOP_ABS)/$(UBOOT_OUT)/rktmp/

	dd if=$(UBOOT_OUT)/rktmp/idbloader.img of=$(PRIVATE_TARGET) conv=notrunc
	dd if=$(UBOOT_OUT)/rktmp/uboot.img of=$(PRIVATE_TARGET) seek=$$(( 16384 - 64 )) conv=notrunc
	dd if=$(UBOOT_OUT)/rktmp/trust.img of=$(PRIVATE_TARGET) seek=$$(( 24576 - 64 )) conv=notrunc
	$(hide) echo "Written to $(PRIVATE_TARGET)"
else
	cp $(UBOOT_OUT)/u-boot-rockchip.bin $(PRIVATE_TARGET)
	$(hide) echo "Written to $(PRIVATE_TARGET)"
endif

.PHONY: uboot_full
uboot_full: uboot_rk

# Include uboot to default target
droidcore-unbundled: uboot_full
