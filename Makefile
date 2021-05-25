UNAME_SYSTEM := $(shell uname -s)

GLMPATH = ../glm
CUDAPATH ?= /usr/local/cuda
NVCC = ${CUDAPATH}/bin/nvcc
CXXFLAGS += -std=c++11 -fvisibility=hidden -I$(OFXPATH)/include -I$(BMDOFXDEVPATH)/Support/include -I$(BMDOFXDEVPATH)/OpenFX-1.4/include -I$(GLMPATH)

ifeq ($(UNAME_SYSTEM), Linux)
	BMDOFXDEVPATH = /opt/resolve/Developer/OpenFX
	OPENCLPATH = /usr
	CXXFLAGS += -I${OPENCLPATH}/include -fPIC -Dlinux -D__OPENCL__
	NVCCFLAGS = --compiler-options="-fPIC"
	LDFLAGS = -shared -fvisibility=hidden -L${CUDAPATH}/lib64 -lcuda -lcudart
	BUNDLE_DIR = Reframe360.ofx.bundle/Contents/Linux-x86-64/
	CUDA_OBJ =  Reframe360CudaKernel.o
	OPENCL_OBJ = Reframe360CLKernel.o
else
	BMDOFXDEVPATH = /Library/Application\ Support/Blackmagic\ Design/DaVinci\ Resolve/Developer/OpenFX
	LDFLAGS = -bundle -fvisibility=hidden -F/Library/Frameworks -framework OpenCL -framework Metal -framework AppKit
	BUNDLE_DIR = Reframe360.ofx.bundle/Contents/MacOS/
	METAL_OBJ = Reframe360Kernel.o
	OPENCL_OBJ = Reframe360CLKernel.o
	METAL_ARM_OBJ = Reframe360Kernel-arm.o
	OPENCL_ARM_OBJ = Reframe360CLKernel-arm.o
	APPLE86_64_FLAG =  -target x86_64-apple-macos10.12
	APPLEARM64_FLAG =  -target arm64-apple-macos11
endif

Reframe360.ofx:  Reframe360.o $(OPENCL_OBJ) $(CUDA_OBJ) $(METAL_OBJ) KernelDebugHelper.o ofxsCore.o ofxsImageEffect.o ofxsInteract.o ofxsLog.o ofxsMultiThread.o ofxsParams.o ofxsProperty.o ofxsPropertyValidation.o
	$(CXX) $(APPLE86_64_FLAG) $^ -o $@ $(LDFLAGS)
	mkdir -p $(BUNDLE_DIR)
	cp Reframe360.ofx $(BUNDLE_DIR)

Reframe360CudaKernel.o: Reframe360CudaKernel.cu
	${NVCC} -c $< $(NVCCFLAGS)

Reframe360.o: Reframe360.cpp
	$(CXX) $(APPLE86_64_FLAG) -c $< $(CXXFLAGS)
	
Reframe360Kernel.o: Reframe360Kernel.mm
	python metal2string.py Reframe360Kernel.metal Reframe360Kernel.h
	$(CXX) $(APPLE86_64_FLAG) -c $< $(CXXFLAGS)

Reframe360CLKernel.o: Reframe360CLKernel.h Reframe360CLKernel.cpp
	$(CXX) $(APPLE86_64_FLAG) -c Reframe360CLKernel.cpp $(CXXFLAGS) -o Reframe360CLKernel.o

KernelDebugHelper.o: KernelDebugHelper.cpp
	$(CXX) $(APPLE86_64_FLAG)  -c "$<" $(CXXFLAGS) -o $@

Reframe360CLKernel.h: Reframe360CLKernel.cl
	python ./HardcodeKernel.py Reframe360CLKernel Reframe360CLKernel.cl

ofxsCore.o: $(BMDOFXDEVPATH)/Support/Library/ofxsCore.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsImageEffect.o: $(BMDOFXDEVPATH)/Support/Library/ofxsImageEffect.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsInteract.o: $(BMDOFXDEVPATH)/Support/Library/ofxsInteract.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsLog.o: $(BMDOFXDEVPATH)/Support/Library/ofxsLog.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsMultiThread.o: $(BMDOFXDEVPATH)/Support/Library/ofxsMultiThread.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsParams.o: $(BMDOFXDEVPATH)/Support/Library/ofxsParams.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsProperty.o: $(BMDOFXDEVPATH)/Support/Library/ofxsProperty.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsPropertyValidation.o: $(BMDOFXDEVPATH)/Support/Library/ofxsPropertyValidation.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

Reframe360-arm.ofx:  Reframe360-arm.o $(OPENCL_ARM_OBJ) $(METAL_ARM_OBJ) KernelDebugHelper-arm.o ofxsCore-arm.o ofxsImageEffect-arm.o ofxsInteract-arm.o ofxsLog-arm.o ofxsMultiThread-arm.o ofxsParams-arm.o ofxsProperty-arm.o ofxsPropertyValidation-arm.o
	$(CXX) $(APPLEARM64_FLAG) $^ -o $@ $(LDFLAGS)
	mkdir -p $(BUNDLE_DIR)
	cp Reframe360.ofx $(BUNDLE_DIR)

Reframe360-arm.o: Reframe360.cpp
	$(CXX) $(APPLEARM64_FLAG) -c $< $(CXXFLAGS) -o $@

Reframe360Kernel-arm.o: Reframe360Kernel.mm
	python metal2string.py Reframe360Kernel.metal Reframe360Kernel.h
	$(CXX) $(APPLEARM64_FLAG) -c $< $(CXXFLAGS) -o $@

KernelDebugHelper-arm.o: KernelDebugHelper.cpp
	$(CXX) $(APPLEARM64_FLAG)  -c "$<" $(CXXFLAGS) -o $@

Reframe360CLKernel-arm.o: Reframe360CLKernel.h Reframe360CLKernel.cpp
	$(CXX) $(APPLEARM64_FLAG) -c Reframe360CLKernel.cpp $(CXXFLAGS) -o Reframe360CLKernel-arm.o
	
ofxsCore-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsCore.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsImageEffect-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsImageEffect.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsInteract-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsInteract.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsLog-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsLog.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsMultiThread-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsMultiThread.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsParams-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsParams.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsProperty-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsProperty.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsPropertyValidation-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsPropertyValidation.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

Reframe360Kernel.h: Reframe360Kernel.metal
	python metal2string.py Reframe360Kernel.metal Reframe360Kernel.h

%.metallib: %.metal
	xcrun -sdk macosx metal -c $< -o $@
	mkdir -p $(BUNDLE_DIR)
	cp $@ $(BUNDLE_DIR)

clean:
	rm -f *.o *.ofx *.metallib Reframe360Kernel.h Reframe360CLKernel.h
	
dist-clean: clean
	rm -fr Reframe360.ofx.bundle Reframe360-universal.ofx Reframe360.ofx Reframe360-arm.ofx

zip: bundle
	zip -r Reframe360.ofx.bundle.zip Reframe360.ofx.bundle
ifdef DEV_IDENTITY
	codesign -f -s $(DEV_IDENTITY) Reframe360.ofx.bundle.zip
endif

ifeq ($(UNAME_SYSTEM), Darwin)
.DEFAULT_GOAL := darwin
	
.PHONY: darwin
darwin: clean zip install

bundle: Reframe360.ofx Reframe360-arm.ofx
ifdef DEV_IDENTITY
	codesign -f -s $(DEV_IDENTITY) Reframe360.ofx 
	codesign -f -s $(DEV_IDENTITY) Reframe360-arm.ofx
endif
	mkdir -p $(BUNDLE_DIR)
	lipo -create -output Reframe360-universal.ofx Reframe360.ofx Reframe360-arm.ofx
	mkdir -p $(BUNDLE_DIR)
	cp Reframe360-universal.ofx $(BUNDLE_DIR)/Reframe360.ofx
ifdef DEV_IDENTITY
	codesign -f -s $(DEV_IDENTITY) Reframe360.ofx.bundle/Contents/MacOS/Reframe360.ofx
endif

install: bundle Reframe360.ofx Reframe360-arm.ofx
	cp Reframe360-universal.ofx $(BUNDLE_DIR)/Reframe360.ofx
	rm -rf /Library/OFX/Plugins/Reframe360.ofx.bundle
	cp -a Reframe360.ofx.bundle /Library/OFX/Plugins/
else
bundle: Reframe360.ofx
	mkdir -p $(BUNDLE_DIR)
	cp Reframe360.ofx $(BUNDLE_DIR)/Reframe360.ofx
	
install: bundle Reframe360.ofx
	rm -rf /usr/OFX/Plugins/Reframe360.ofx.bundle
	mkdir -p /usr/OFX/Plugins/
	cp -a Reframe360.ofx.bundle /usr/OFX/Plugins/
endif
