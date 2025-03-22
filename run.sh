#!/bin/bash

if [ -d "content" ]; then
    rm -f sql/insert.sql

    for dir in content/*; do
      for dir2 in $dir/*; do
        echo "Processing $dir2"
        if [ -d "$dir2" ]; then
            title=$(jq -r '.title' "$dir2/description.json")
            banner_image=$(jq -r '.banner_image' "$dir2/description.json")
            content=$(cat "$dir2/content.md")
            content=$(echo "$content" | sed "s/'/''/g")
            created_at=$(jq -r '.created_at' "$dir2/description.json")
            params=$(jq -r '.params' "$dir2/description.json")
            
            echo "INSERT INTO contents (title, content, banner_image, params, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by)" >> sql/insert.sql
            echo "VALUES ('$title', '$content', '$banner_image', '$params', '$created_at', 'dongtran', NULL, NULL, NULL, NULL);" >> sql/insert.sql
        fi
      done
    done

    echo "SQL file generated successfully."
else
    echo "Content directory not found in the project."
    exit 1
fi
