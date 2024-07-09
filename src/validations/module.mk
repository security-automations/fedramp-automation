.PHONY: init-validations clean-validations test-validations build-validations

VALIDATIONS_DIR := src/validations
DIST_DIR := dist/content
FORMATS := xml yaml json

# OSCAL CLI commands
OSCAL_VALIDATE := npx oscal validate
OSCAL_CONVERT := npx oscal convert

# Schematron and XSLT related variables (kept for reference)
SAXON_VERSION := 10.8
SAXON_JAR := Saxon-HE-$(SAXON_VERSION).jar
SAXON_LOCATION := saxon/Saxon-HE/$(SAXON_VERSION)/$(SAXON_JAR)
SAXON_URL := https://repo1.maven.org/maven2/net/sf/$(SAXON_LOCATION)
export SAXON_OPTS = allow-foreign=true diagnose=true
export SAXON_CP = vendor/$(SAXON_JAR)

COMPILE_SCH := bash $(VALIDATIONS_DIR)/bin/compile-sch.sh
EVAL_SCHEMATRON := bash $(VALIDATIONS_DIR)/bin/evaluate-compiled-schematron.sh
EVAL_XSPEC := TEST_DIR=$(VALIDATIONS_DIR)/report/test bash vendor/xspec/bin/xspec.sh -e -s -j

OSCAL_SCHEMATRON := $(wildcard $(VALIDATIONS_DIR)/rules/**/*.sch)
STYLEGUIDE_SCHEMATRON := $(wildcard $(VALIDATIONS_DIR)/styleguides/*.sch)
SRC_SCH := $(OSCAL_SCHEMATRON) $(STYLEGUIDE_SCHEMATRON)

XSL_SCH := $(patsubst $(VALIDATIONS_DIR)/%.sch,$(VALIDATIONS_DIR)/target/%.sch.xsl,$(SRC_SCH))

init-validations: $(SAXON_CP)  ## Initialize validations dependencies
	npm install oscal

$(SAXON_CP):  ## Download Saxon-HE to the vendor directory
	curl -f -H "Accept: application/zip" -o "$(SAXON_CP)" "$(SAXON_URL)"

clean-validations:  ## Clean validations artifact
	@echo "Cleaning validations..."
	rm -rf $(VALIDATIONS_DIR)/target
	rm -rf $(DIST_DIR)
	git clean -xfd $(VALIDATIONS_DIR)/report

include src/validations/styleguides/module.mk
include src/validations/test/rules/module.mk
include src/validations/test/styleguides/module.mk

test-validations: $(SAXON_CP) test-styleguides test-validations-styleguides test-validations-rules  ## Test validations
	@echo "Running OSCAL validations..."
	@bash -c '
		set -e
		for format in $(FORMATS); do
			echo "Validating $$format files..."
			find $(DIST_DIR)/$$format -type f -exec $(OSCAL_VALIDATE) -f {} \;
			echo "Validating $$format files with FedRAMP extension..."
			find $(DIST_DIR)/$$format -type f -exec $(OSCAL_VALIDATE) -f {} -e fedramp \;
		done
	'

# Schematron to XSL (kept for reference)
$(VALIDATIONS_DIR)/target/%.sch.xsl: $(VALIDATIONS_DIR)/%.sch
	@echo "Building Schematron $< to $@..."
	$(COMPILE_SCH) $< $@

# Apply xspec (kept for reference)
$(VALIDATIONS_DIR)/report/test/%-junit.xml: $(VALIDATIONS_DIR)/test/%.xspec
	$(EVAL_XSPEC) $

build-validations: $(SAXON_CP) $(XSL_SCH)
	@echo "Converting and validating content..."
	@bash -c '
		set -e
		SRC_DIR="src/content"
		DIST_DIR="$(DIST_DIR)"
		FORMATS="$(FORMATS)"

		# Create dist directory if it does not exist
		mkdir -p "$$DIST_DIR"

		# Create format-specific directories
		for format in $$FORMATS; do
			mkdir -p "$$DIST_DIR/$$format"
		done

		# Function to process files
		process_file() {
			local file="$$1"
			local rel_path="$${file#$$SRC_DIR/}"
			
			for format in $$FORMATS; do
				output_path="$$DIST_DIR/$$format/$$rel_path"
				output_dir="$$(dirname "$$output_path")"
				
				# Create output directory if it does not exist
				mkdir -p "$$output_dir"
				
				# Convert file
				$(OSCAL_CONVERT) -f "$$file" -o "$$output_path"
				echo "Converted $$file to $$format"
				
				# Validate converted file
				if $(OSCAL_VALIDATE) -f "$$output_path"; then
					echo "Validated $$output_path"
				else
					echo "Validation failed for $$output_path"
				fi
				
				# Validate with FedRAMP extension
				if $(OSCAL_VALIDATE) -f "$$output_path" -e fedramp; then
					echo "Validated $$output_path with FedRAMP extension"
				else
					echo "FedRAMP validation failed for $$output_path"
				fi
			done
		}

		# Export the function so it can be used in find
		export -f process_file

		# Process all files
		find "$$SRC_DIR" -type f -exec bash -c "process_file \"{}\"" \;

		echo "Conversion and validation completed."
	'