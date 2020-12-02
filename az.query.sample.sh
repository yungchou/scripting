az sig image-definition list -g da1020 --gallery-name da1020.SIG \
  --query "[].[
    location,name,osState,osType,id,identifier.offer,identifier.publisher,identifier.sku
    ]"
