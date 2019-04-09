# Shiny Project for BIO594

## Overview
There's an assumption that you're connecting this to a PostgreSQL database which is replicating Netsuite tables to a `netsuite` schema. For example, there must be a `transactions` table located at `netsuite.transactions`.

This can be run locally within RStudio but newer versions of packages may have deprecated functionality. As such, the preferred method is a versioned docker image for RStudio 3.5.3.

## Installation

Build docker
1. Copy `config-sample.yml` to `config.yml`
2. Edit `config.yml` with the server connections and credentials
Run docker
1. One image for rstudio web
2. One image for shiny

## Usage

Browse to the l

