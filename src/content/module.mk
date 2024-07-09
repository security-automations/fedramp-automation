.PHONY: init-content build-content test-content

# Variables
SRC_DIR := src/content
DIST_DIR := dist/content
FORMATS := xml yaml json

# Install dependencies
init-content:
	npm install oscal

# Build and validate content
build-content:
	@echo "Converting and validating content..."
	@bash -c '
		set -e
		SRC_DIR="$(SRC_DIR)"
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
				npx oscal convert -f "$$file" -o "$$output_path"
				echo "Converted $$file to $$format"
				
				# Validate converted file
				if npx oscal validate -f "$$output_path"; then
					echo "Validated $$output_path"
				else
					echo "Validation failed for $$output_path"
				fi
				
				# Validate with FedRAMP extension
				if npx oscal validate -f "$$output_path" -e fedramp; then
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

# Additional tests if needed
test-content:
	@echo "Running additional tests..."
	# Add any additional test commands here

# Default target
all: init-content build-content test-content