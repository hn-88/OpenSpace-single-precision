#!/bin/bash

# OpenSpace 64-bit to 32-bit OpenGL Conversion Script
# This script patches OpenSpace files to use 32-bit OpenGL calls for Apple Silicon compatibility
# Usage: ./patch_openspace.sh [path_to_openspace_root]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the OpenSpace root directory
OPENSPACE_ROOT="${1:-.}"

if [ ! -d "$OPENSPACE_ROOT" ]; then
    echo -e "${RED}Error: Directory $OPENSPACE_ROOT does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}Starting OpenSpace 64-bit to 32-bit OpenGL conversion...${NC}"
echo "Working directory: $OPENSPACE_ROOT"

# Backup function
create_backup() {
    local file="$1"
    if [ ! -f "${file}.backup" ]; then
        cp "$file" "${file}.backup"
        echo -e "${YELLOW}Created backup: ${file}.backup${NC}"
    fi
}

# Counter for changes
total_changes=0

# Function to apply sed changes and count them
apply_patch() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"
    
    if [ -f "$file" ]; then
        create_backup "$file"
        
        # Check if pattern exists before applying
        if grep -q "$pattern" "$file" 2>/dev/null; then
            sed -i.tmp "s|$pattern|$replacement|g" "$file"
            rm -f "${file}.tmp"
            local count=$(grep -c "$replacement" "$file" || echo "0")
            if [ "$count" -gt 0 ]; then
                echo "  ✓ $description in $file"
                ((total_changes++))
            fi
        fi
    fi
}

echo -e "\n${GREEN}=== Patching GLSL Shaders ===${NC}"

# Pattern 1: dmat4 -> mat4 (uniform declarations)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    apply_patch "$file" \
        "uniform dmat4" \
        "uniform mat4" \
        "Changed dmat4 uniforms to mat4"
done

# Pattern 2: dvec3 -> vec3 (uniform declarations)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    apply_patch "$file" \
        "uniform dvec3" \
        "uniform vec3" \
        "Changed dvec3 uniforms to vec3"
done

# Pattern 3: dvec4 -> vec4 (uniform declarations)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    apply_patch "$file" \
        "uniform dvec4" \
        "uniform vec4" \
        "Changed dvec4 uniforms to vec4"
done

# Pattern 4: dvec2 -> vec2 (uniform declarations)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    apply_patch "$file" \
        "uniform dvec2" \
        "uniform vec2" \
        "Changed dvec2 uniforms to vec2"
done

# Pattern 5: double -> float (uniform declarations)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    apply_patch "$file" \
        "uniform double" \
        "uniform float" \
        "Changed double uniforms to float"
done

# Pattern 6: dmat4 -> mat4 (variable declarations and casts)
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        # More complex patterns requiring perl for better regex
        perl -i -pe 's/\bdmat4\s+/mat4 /g' "$file"
        perl -i -pe 's/\bdmat3\s+/mat3 /g' "$file"
        perl -i -pe 's/\bdvec4\(/vec4(/g' "$file"
        perl -i -pe 's/\bdvec3\(/vec3(/g' "$file"
        perl -i -pe 's/\bdvec2\(/vec2(/g' "$file"
        perl -i -pe 's/\bdouble\s+/float /g' "$file"
    fi
done

# Pattern 7: Literal suffixes LF -> F
find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        perl -i -pe 's/(\d+\.\d+)LF/$1F/g' "$file"
    fi
done

echo -e "\n${GREEN}=== Patching C++ Files ===${NC}"

# Pattern 8: setUniform with dmat4 -> mat4 casts
find "$OPENSPACE_ROOT" -type f -name "*.cpp" | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        # Add static_cast<glm::mat4> around glm::dmat4 in setUniform calls
        perl -i -pe 's/setUniform\s*\([^,]+,\s*((?:glm::)?dmat4\([^)]+\)[^)]*)\)/setUniform\($1, static_cast<glm::mat4>($2)\)/g' "$file"
        
        # Handle cases where modelViewTransform, projectionTransform etc are dmat4
        perl -i -pe 's/setUniform\s*\(([^,]+),\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\)/
            if ($2 =~ m\/(modelViewTransform|projectionTransform|modelMatrix|viewTransform|cameraViewProjectionMatrix|modelViewProjectionMatrix)\/) {
                "setUniform($1, static_cast<glm::mat4>($2))"
            } else {
                "setUniform($1, $2)"
            }
        /ge' "$file"
    fi
done

# Pattern 9: setUniform with dvec3 -> vec3 casts
find "$OPENSPACE_ROOT" -type f -name "*.cpp" | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        # Add static_cast<glm::vec3> for camera positions and similar
        perl -i -pe 's/setUniform\s*\(([^,]+),\s*data\.camera\.(positionVec3|lookUpVectorWorldSpace)\(\s*\)\s*\)/setUniform($1, static_cast<glm::vec3>(data.camera.$2()))/g' "$file"
        
        # Handle eyePosition and similar dvec3 variables
        perl -i -pe 's/setUniform\s*\(([^,]+),\s*(eyePosition|cameraPosition|cameraUp|cameraLookUp)\s*\)/setUniform($1, static_cast<glm::vec3>($2))/g' "$file"
    fi
done

# Pattern 10: Type declarations in C++ headers and source
find "$OPENSPACE_ROOT" -type f \( -name "*.h" -o -name "*.cpp" \) | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        # Change glm::dmat4 member variables to glm::mat4 in specific contexts
        perl -i -pe 's/(glm::)?dmat4\s+(_modelTransform|_transform|modelTransform)/glm::mat4 $2/g' "$file"
        
        # Change struct member types
        perl -i -pe 's/(double|glm::dvec3|glm::dvec4)\s+(umbra|penumbra|radiusSource|radiusCaster|sourceCasterVec|casterPositionVec)/float $2/g' "$file"
        perl -i -pe 's/glm::dvec3\s+(sourceCasterVec)/glm::vec3 $1/g' "$file"
    fi
done

# Pattern 11: uint32 -> uint32_t for compatibility
find "$OPENSPACE_ROOT" -type f \( -name "*.cpp" -o -name "*.h" \) | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        perl -i -pe 's/static_cast<uint32>/static_cast<uint32_t>/g' "$file"
    fi
done

# Pattern 12: Specific casting patterns in calculations
find "$OPENSPACE_ROOT" -type f -name "*.cpp" | while read file; do
    if [ -f "$file" ]; then
        create_backup "$file"
        # Cast various transform operations
        perl -i -pe 's/invModelMatrix \* glm::dvec4/invModelMatrix * static_cast<glm::vec4>/g' "$file"
        perl -i -pe 's/modelTransform \* glm::dvec4/modelTransform * static_cast<glm::vec4>/g' "$file"
        perl -i -pe 's/glm::inverse\(data\.camera\.combinedViewMatrix\(\)\)/glm::inverse(static_cast<glm::mat4>(data.camera.combinedViewMatrix()))/g' "$file"
    fi
done

echo -e "\n${GREEN}=== Summary ===${NC}"
echo "Total file modifications: $total_changes"
echo -e "${YELLOW}Note: Backup files (.backup) have been created for all modified files${NC}"

echo -e "\n${GREEN}=== Verification Steps ===${NC}"
echo "1. Review the changes with: git diff"
echo "2. Build the project to check for compilation errors"
echo "3. Test the application on Apple Silicon hardware"
echo "4. If issues occur, restore from .backup files"

echo -e "\n${GREEN}To restore all backups:${NC}"
echo "find $OPENSPACE_ROOT -name '*.backup' -exec bash -c 'mv \"\$0\" \"\${0%.backup}\"' {} \;"

echo -e "\n${GREEN}To remove all backups after successful testing:${NC}"
echo "find $OPENSPACE_ROOT -name '*.backup' -delete"

echo -e "\n${GREEN}Patching complete!${NC}"
