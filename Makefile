# ============
# Main targets
# ============


# -------------
# Configuration
# -------------

$(eval venvpath     := .venv)
$(eval pip          := $(venvpath)/bin/pip)
$(eval python       := $(venvpath)/bin/python)
$(eval pytest       := $(venvpath)/bin/pytest)
$(eval bumpversion  := $(venvpath)/bin/bumpversion)
$(eval twine        := $(venvpath)/bin/twine)
$(eval sphinx       := $(venvpath)/bin/sphinx-build)
$(eval black        := $(venvpath)/bin/black)
$(eval isort        := $(venvpath)/bin/isort)


# Setup Python virtualenv
setup-virtualenv:
	@test -e $(python) || python3 -m venv $(venvpath)


# -------
# Testing
# -------

# Run the main test suite
test:
	@test -e $(pytest) || $(MAKE) install-tests
	@$(pytest) --keepalive --show-capture=all -vvv tests

test-teardown:
	docker rm grafana-wtf-test --force

test-refresh: install-tests test

test-junit: install-tests
	@$(pytest) tests --junit-xml .pytest_results/pytest.xml

test-coverage: install-tests
	@$(pytest) tests \
		--junit-xml .pytest_results/pytest.xml \
		--cov mqttwarn --cov-branch \
		--cov-report term-missing \
		--cov-report html:.pytest_results/htmlcov \
		--cov-report xml:.pytest_results/coverage.xml


# ----------
# Formatting
# ----------
format: install-releasetools
	$(isort) .
	$(black) .


# -------
# Release
# -------

# Release this piece of software
# Synopsis:
#   make release bump=minor  (major,minor,patch)
release: bumpversion push build pypi-upload


# -------------
# Documentation
# -------------

# Build the documentation
docs-html: install-doctools
	touch doc/index.rst
	export SPHINXBUILD="`pwd`/$(sphinx)"; cd doc; make html


# ===============
# Utility targets
# ===============
bumpversion: install-releasetools
	@$(bumpversion) $(bump)

push:
	git push && git push --tags

build:
	@$(python) -m build

pypi-upload: install-releasetools
	twine upload --skip-existing --verbose dist/{*.tar.gz,*.whl}

install-doctools: setup-virtualenv
	@$(pip) install --quiet --requirement requirements-docs.txt --upgrade

install-releasetools: setup-virtualenv
	@$(pip) install --quiet --requirement requirements-release.txt --upgrade

install-tests: setup-virtualenv
	@$(pip) install --quiet --editable .[test] --upgrade
	@$(python) setup.py --quiet develop
	@touch $(venvpath)/bin/activate
	@mkdir -p .pytest_results



# -------
# Project
# -------

grafana-start:
	cd tests/grafana; docker-compose up
