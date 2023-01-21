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

TOP_ABS := $(realpath $(TOP))

KERNEL_VERSION := 5.15
KERNEL_CROSS_COMPILE_PREFIX := $(TOP)/prebuilts/gcc/linux-x86/host/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
KERNEL_SRC := $(TOP)/kernel/android13-5.15-lts
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_BINARY := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/Image
KERNEL_DTB_OUT := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/dts/$(KERNEL_DTB)

KERNEL_BASE_CONFIG := $(TOP)/kernel/configs/android-$(KERNEL_VERSION)/android-base.config

KERNEL_CMAKE_CMD := \
	PATH=/usr/bin:$$PATH \
	ARCH=$(TARGET_ARCH) \
	CROSS_COMPILE=$(TOP_ABS)/$(KERNEL_CROSS_COMPILE_PREFIX) \
	$(MAKE) -C $(KERNEL_SRC) O=$(TOP_ABS)/$(KERNEL_OUT)

$(KERNEL_OUT):
	$(hide) mkdir -p $(KERNEL_OUT)

$(KERNEL_CONFIG): $(KERNEL_SRC)/Makefile $(KERNEL_CONFIG_FRAGMENTS) $(KERNEL_OUT)
	$(hide) echo "Configuring kernel..."
ifdef KERNEL_CONFIG_FRAGMENTS
	PATH=/usr/bin:$$PATH $(KERNEL_SRC)/scripts/kconfig/merge_config.sh -m -O $(KERNEL_OUT) $(KERNEL_BASE_CONFIG) $(KERNEL_CONFIG_FRAGMENTS)
else
	cp $(KERNEL_BASE_CONFIG) $(KERNEL_OUT)/.config
endif
	$(KERNEL_CMAKE_CMD) olddefconfig

$(KERNEL_BINARY): PRIVATE_KERNEL_OUT := $(PRODUCT_OUT)/kernel-$(KERNEL_VERSION)
$(KERNEL_BINARY): $(KERNEL_CONFIG)
	$(hide) echo "Building kernel..."
	$(KERNEL_CMAKE_CMD) > $(OUT_DIR)/kernel_build.log 2>&1
	$(hide) cp -v $@ $(PRIVATE_KERNEL_OUT)

$(KERNEL_DTB_OUT): PRIVATE_DTB_OUT := $(PRODUCT_OUT)/$(notdir $(KERNEL_DTB))
$(KERNEL_DTB_OUT): PRIVATE_DTS := $(patsubst %.dtb,%.dts,$(KERNEL_SRC)/arch/$(TARGET_ARCH)/boot/dts/$(KERNEL_DTB))
$(KERNEL_DTB_OUT): $(KERNEL_CONFIG) $(PRIVATE_DTS)
	$(hide) echo "Building dtb..."
	$(KERNEL_CMAKE_CMD) $(KERNEL_DTB)
	$(hide) cp -v $@ $(PRIVATE_DTB_OUT)

.PHONY: kernelconfig
kernelconfig: $(KERNEL_CONFIG)

.PHONY: kernel
kernel: $(KERNEL_BINARY)

.PHONY: dtb
dtb: $(KERNEL_DTB_OUT)
