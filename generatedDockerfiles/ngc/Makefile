VERSION ?= 0.7.0

GIT_COMMIT := $(shell git rev-parse --short HEAD)
DIRTY_FILES := $(shell git diff-files --ignore-submodules)
DIRTY_INDEX := $(shell git diff-index --cached HEAD --ignore-submodules)
ifneq ($(DIRTY_FILES),)
GIT_COMMIT := dirty
endif
ifneq ($(DIRTY_INDEX),)
GIT_COMMIT := dirty
endif
ifeq ($(GIT_COMMIT), dirty)
$(warning !!!!!!!! WARNING: Dirty or uncommited source tree !!!!!!!!)
endif


.PHONY: current legacy clean
all: current legacy
	docker images | grep rapids

current:
	docker build \
		-f rapids.Dockerfile \
		-t rapids:$(VERSION)-cuda10.0-$(GIT_COMMIT) \
		--build-arg CUDA_VERSION=10.0 \
		--build-arg BASE_IMAGE=devel-ubuntu18.04 .

legacy:
	docker build \
		-f rapids.Dockerfile \
		-t rapids:$(VERSION)-cuda9.2-$(GIT_COMMIT) \
		--build-arg CUDA_VERSION=9.2 \
		--build-arg BASE_IMAGE=devel-ubuntu16.04 .

clean:
	-docker rmi rapids:$(VERSION)-$(GIT_COMMIT) rapids:$(VERSION)-cuda9.2-$(GIT_COMMIT)

print-%: ; @echo $*=$($*)
