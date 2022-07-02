## Current status

All blocks serialize into valid JSON, sharing some common structures.

The editor itself, will serialize into json with a single, root field: 

```JSON
{
  "blocks": []
}
```

Each individual block is then a JSON containing at minimum a `type`, an `id` and
a free form `data` field. 

For example, this is what a contenteditable p block will look like:

```JSON
{
  "id": "7040fb6a-9e17-4c7e-a4d8-70c8427be9dc",
  "type": "contenteditable",
  "data": {
    "kind" => "p",
    "cells": [
      {
        "id": "4cdc009b-c0c0-4bc1-94d6-e353ac25afa7",
        "modifiers": [],
        "text": "This is the title of your page"
      }
    ]
  }
}
```

A different example, the table block, has the same root fields, but the 
value of `data` is different:

```JSON
{
  "id": "01de4dc5-e9bb-47db-aa90-b95760012754",
  "type": "table",
  "data" => {
    "header_rows": [["ID", "First Name", "Last Name"]],
    "rows": [
      ["1", "John", "Doe"],
      ["2", "Jane", "Doe"]
    ]
  }
}
```

### Reasoning

The `id` field serves as something to match and identify blocks across actions 
and changes.

The `type` field allows the system to identify the block and properly 
serialize/normalize it.

The `data` field is the actual, custom data of the block.
