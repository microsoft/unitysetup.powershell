# Test Runner Guide

This document provides an overview of the test runner setup and how to use it for both end-to-end (E2E) and unit testing in this project.

## Table of Contents

1. [Overview](#overview)
2. [Environment Setup](#environment-setup)
3. [Running the Tests](#running-the-tests)
   - [End-to-End Tests](#end-to-end-tests)
   - [Unit Tests](#unit-tests)
4. [Folder Structure](#folder-structure)
5. [Additional Information](#additional-information)

## Overview

The test runner is designed to facilitate both end-to-end and unit testing on real Unity project targets using UnitySetup cmdlets. Including real generation of Unity Package Manager auth tokens. (You may need to delete your .toml file locally for fresh runs)

## Environment Setup (End to End Tests)

Before running the tests, ensure that you have one or more Unity projects locally that can serve for the following environment variables:

- `TEST_UNITY_FOLDERPATH`: Path to the root folder of a Unity project.
- `TEST_UNITY_MANIFESTPATH`: Path to a valid Unity project manifest.
- `TEST_UNITY_MULTIFOLDERPATH`: Path to the root folder of a Unity project with multiple manifests in subfolders less than 5 directories deep.
- `TEST_UNITY_MANIFESTLIKEPATH`: Path to a valid Unity project manifest-like file. (Any valid JSON file with scoped registries)
- `TEST_AZURESUBSCRIPTION_ID`: Azure Subscription ID required for certain test scenarios.

These environment variables can be set interactively when running the tests or manually before running the test scripts.

## Running the Tests

### End-to-End Tests

The end-to-end tests are located in the `E2ETests` folder. These tests validate the entire workflow, including real environment variables.

To run the end-to-end tests:

```powershell
cd Tests
.\e2etests.ps1
```

This script will import the necessary modules and run all tests in the `E2ETests` folder, using the provided environment variables.

### Unit Tests

The unit tests are located in the `UnitTests` folder. These tests use mocked data and functions to isolate and validate individual components.

To run the unit tests:

```powershell
cd Tests
.\unittests.ps1
```

This script will run all unit tests in the `UnitTests` folder, using mock functions and predefined input/output.

## Additional Information

- The test scripts utilize `Pester` and `PSScriptAnalyzer` modules. Ensure these modules are installed and available in your environment before running the tests.
- Test results can be output to the console or captured programmatically using the `-PassThru` switch.

For further customization, review the provided test scripts and modify the parameters or mocks as needed.
