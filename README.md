# Shiny Project for BIO594

## Overview
There's an assumption that you're connecting this to a PostgreSQL database which is replicating Netsuite tables to a `netsuite` schema. For example, there must be a `transactions` table located at `netsuite.transactions`.

The demo for class is actually using a different branch which has static data in it to get around the VPN issues with the real code. That is the `for-class` branch in this repo.

## Installation

If you're using the master branch, you'll need VPN into the TT network and appropriate credentials. Set them as follows:

1. Copy `config-sample.yml` to `config.yml`
2. Edit `config.yml` with the server connections and credentials

The `for-class` branch should would without issue.