cwlVersion: v1.2
class: ExpressionTool
requirements:
  InlineJavascriptRequirement: {}
inputs:
  urls:
      - type: array
        items: [string, File]
  count: int
outputs:
  batches:
    type:
      - type: array
        items:
          type: array
          items: [string, File]

expression: |
  ${
  var batches = [];
  var batchcount = Math.min(inputs.count, inputs.urls.length);
  for (var i = 0; i < batchcount; i++) {
    batches.push([]);
  }
  for (var n = 0; n < inputs.urls.length; n++) {
    batches[n % batchcount].push(inputs.urls[n]);
  }
  return {"batches": batches};
  }
