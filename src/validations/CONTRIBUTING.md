# Validations

## Project Structure

All directory references are local to the `fedramp-automation/src/validations`

* `bin` has the validation script.
* `docs/adr` has a list of [Architectural Decision Records](https://adr.github.io) in which the product team documented technical decisions for the project.
* `report/test` for XSpec and SCH test outputs
* `report/schematron` for the final validations in Schematron SVRL reporting format.
* `rules` has the Schematron files for the SSP.
* `styleguides` for XSpec and Schematron styling Schematron.
* `target` for intermediary and complied artifacs, e.g. XSLT stylesheets, etc.
* `test` for any XSpec or other testing artifacts.
* `test/demo` has the demo XML file.

## Validate XML Files using Schematron

**Prerequesite**: *To ensure that you have all required dependencies (see .gitmodules), run the following command:*

```sh
git submodule update --init --recursive
```

## Analyzing Changes to OSCAL Data Models to Update Rules

OSCAL has abstract information models that are converted into concrete data models into XML and JSON.

As a developer, you can look at individual OSCAL files that must conform to schemas for these data models, including SSPs, Components, SAPs, SARs, and POA&Ms. However, looking at individual examples for each respective model will be exhaustive and time-consuming.

The schemas for the models themselves are designed and programmatically [designed, cross-referenced between JSON and XML, and generated with appropriate schema validation tools by way of the NIST Metaschema project](https://pages.nist.gov/OSCAL/documentation/schema/overview/). Therefore, it is most prudent to focus analysis on the changes in the version-controlled Metaschema declarations, as they define the abstract information model. This information model is used to generate concrete data models in JSON and XML, to be validated by JSON Schema and XSD, respectively.

Developers ought to review the following relevant information sources, in order of least to most effort.

* [Release notes from the NIST OSCAL Development Team](https://github.com/usnistgov/OSCAL/blob/master/src/release/release-notes.md), where they summarize model changes in their own words from version to version.
* [XSLT "up-convert" transforms](https://github.com/usnistgov/OSCAL/tree/f44426e0ec14431b88833dbd381b5434d0892403/src/release/content-upgrade) give specific declarative detail on how to modify the OSCAL XML data models.
* The source code of the Metaschema models, filtering on the release tags. Developers can use the Github web interface to compare Metaschema files, [such as this example comparison between release candidate versions `1.0.0-rc1` and `1.0.0-rc2`](https://github.com/usnistgov/OSCAL/compare/v1.0.0-rc1...v1.0.0-rc2). Focus on the files in the `src/metaschema` directory.

Per [18F/fedramp-automation#61](https://github.com/18F/fedramp-automation/issues/61), programmatic diff utilities to semantically analyze the differences between OSCAL versions requires resources not available at this time.

### Formatting XML

When contributing, please use the following indentation and formatting settings. Formatting options are chosen for readability, and for clean git diffs.

For Oxygen XML Editor:
- Indent size 4
- 150 character line width (folding threshold)
- Preserve empty lines
- Preserve line breaks in attributes
- Indent inline elements
- Sort attributes
- Add space before slash in empty elements
- Break line before an attribute name

