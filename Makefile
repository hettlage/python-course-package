# Execute the "targets" in this file with `make <target>` e.g., `make test`.
#
# You can also run multiple in sequence, e.g. `make clean lint test serve-coverage-report`

clean:
	bash run.sh clean

generate-project:
	bash run.sh generate-project

help:
	bash run.sh help

install:
	bash run.sh install

lint:
	bash run.sh lint
