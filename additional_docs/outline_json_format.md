## Current status

All blocks serialize into valid JSON, sharing some common structures.

The editor itself, will serialize into json with a single, root field: 

```JSON
{
  "blocks": []
}
```

Each individual block is then a JSON containing at minimum a `type`, and an `id`
field. For example, this is what a p block will look like:

```JSON
{
  "id": "7040fb6a-9e17-4c7e-a4d8-70c8427be9dc",
  "type": "p",
  "content": [
    {
      "id": "4cdc009b-c0c0-4bc1-94d6-e353ac25afa7",
      "modifiers": [],
      "text": "This is the title of your page"
    }
  ]
}
```

A different example, the table block, shares some of the fields, but has its own:

```JSON
{
  "header_rows": [["", "", "", "", "", "", ""]],
  "id": "01de4dc5-e9bb-47db-aa90-b95760012754",
  "rows": [
    ["here", "doesnt", "work", "that", "great", "but", "hey"],
    ["it", "kinda", "works", "still", "and it", "will", "kee"]
  ],
  "type": "table"
}
```

### Reasoning

The `id` field serves as something to match and identify blocks across actions 
and changes.

The `type` field allows the system to identify the block and properly 
serialize/normalize it.

Everything else is data the block contains.

## Future plans

Ideally, the other fields are all moved into a single `data` field, 
to make the structure even more uniform.