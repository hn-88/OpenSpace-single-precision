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

# Function to apply sed changes safely
apply_sed() {
    local file="$1"
    shift
    local description="$*"
    
    if [ -f "$file" ]; then
        create_backup "$file"
        # Apply all sed commands passed as arguments
        local changes_made=0
        for pattern in "$@"; do
            if [ "$pattern" != "$description" ]; then
                if sed -i.sedtmp "$pattern" "$file" 2>/dev/null; then
                    changes_made=1
                fi
                rm -f "${file}.sedtmp"
            fi
        done
        if [ $changes_made -eq 1 ]; then
            echo "  ✓ $description"
            ((total_changes++))
        fi
    fi
}

echo -e "\n${GREEN}=== Patching GLSL Shaders ===${NC}"

# Find all shader files
shader_files=$(find "$OPENSPACE_ROOT" -type f \( -name "*.glsl" -o -name "*.vs" -o -name "*.fs" -o -name "*.gs" -o -name "*.ge" \) 2>/dev/null || true)

for file in $shader_files; do
    if [ -f "$file" ]; then
        create_backup "$file"
        
        # Apply all shader transformations
        sed -i.tmp '
            # Uniform declarations
            s/uniform dmat4/uniform mat4/g
            s/uniform dmat3/uniform mat3/g
            s/uniform dvec4/uniform vec4/g
            s/uniform dvec3/uniform vec3/g
            s/uniform dvec2/uniform vec2/g
            s/uniform double/uniform float/g
            
            # Type declarations (word boundaries)
            s/\([^a-zA-Z_]\)dmat4 /\1mat4 /g
            s/\([^a-zA-Z_]\)dmat3 /\1mat3 /g
            s/\([^a-zA-Z_]\)dvec4 /\1vec4 /g
            s/\([^a-zA-Z_]\)dvec3 /\1vec3 /g
            s/\([^a-zA-Z_]\)dvec2 /\1vec2 /g
            s/\([^a-zA-Z_]\)double /\1float /g
            
            # Type casts
            s/dmat4(/mat4(/g
            s/dmat3(/mat3(/g
            s/dvec4(/vec4(/g
            s/dvec3(/vec3(/g
            s/dvec2(/vec2(/g
            
            # Literal suffixes
            s/\([0-9]\+\.[0-9]\+\)LF/\1F/g
            s/\([0-9]\+\)LF/\1F/g
        ' "$file"
        
        rm -f "${file}.tmp"
        echo "  ✓ Patched shader: $(basename $file)"
    fi
done

echo -e "\n${GREEN}=== Patching C++ Files ===${NC}"

# Find all C++ source files
cpp_files=$(find "$OPENSPACE_ROOT" -type f -name "*.cpp" 2>/dev/null || true)

for file in $cpp_files; do
    if [ -f "$file" ]; then
        create_backup "$file"
        
        # Pattern 1: Add casts for matrix uniforms
        sed -i.tmp '
            # Cast modelViewTransform, projectionTransform, etc. to mat4
            s/setUniform(\([^,]*\), \(modelViewTransform\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(projectionTransform\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(modelMatrix\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(viewTransform\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(modelViewProjectionMatrix\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(cameraViewProjectionMatrix\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(modelViewProjectionTransform\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(modelViewTransform\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(model\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(view\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            s/setUniform(\([^,]*\), \(projection\))/setUniform(\1, static_cast<glm::mat4>(\2))/g
            
            # Cast camera position/direction vectors to vec3
            s/setUniform(\([^,]*\), data\.camera\.positionVec3())/setUniform(\1, static_cast<glm::vec3>(data.camera.positionVec3()))/g
            s/setUniform(\([^,]*\), data\.camera\.lookUpVectorWorldSpace())/setUniform(\1, static_cast<glm::vec3>(data.camera.lookUpVectorWorldSpace()))/g
            
            # Cast common vec3 variables
            s/setUniform(\([^,]*\), \(eyePosition\))/setUniform(\1, static_cast<glm::vec3>(\2))/g
            s/setUniform(\([^,]*\), \(cameraPosition\))/setUniform(\1, static_cast<glm::vec3>(\2))/g
            s/setUniform(\([^,]*\), \(cameraUp\))/setUniform(\1, static_cast<glm::vec3>(\2))/g
            s/setUniform(\([^,]*\), \(cameraLookUp\))/setUniform(\1, static_cast<glm::vec3>(\2))/g
            
            # Cast inverse matrix operations
            s/glm::inverse(data\.camera\.combinedViewMatrix())/glm::inverse(static_cast<glm::mat4>(data.camera.combinedViewMatrix()))/g
            
            # Cast matrix multiplications with dvec4
            s/\* glm::dvec4(/* static_cast<glm::vec4>(/g
            
            # Cast uint32 to uint32_t
            s/static_cast<uint32>/static_cast<uint32_t>/g
            
            # Cast j2000Seconds to float for time uniforms
            s/data\.time\.j2000Seconds()/static_cast<float>(data.time.j2000Seconds())/g
        ' "$file"
        
        rm -f "${file}.tmp"
        ((total_changes++))
    fi
done

# Find all C++ header files
header_files=$(find "$OPENSPACE_ROOT" -type f -name "*.h" 2>/dev/null || true)

for file in $header_files; do
    if [ -f "$file" ]; then
        create_backup "$file"
        
        sed -i.tmp '
            # Change member variable types
            s/glm::dmat4 \(_modelTransform\)/glm::mat4 \1/g
            s/glm::dmat4 \(modelTransform\)/glm::mat4 \1/g
            s/glm::dmat4 \(_transform\)/glm::mat4 \1/g
            
            # Change struct members for shadow calculations
            s/double umbra/float umbra/g
            s/double penumbra/float penumbra/g
            s/double radiusSource/float radiusSource/g
            s/double radiusCaster/float radiusCaster/g
            s/glm::dvec3 sourceCasterVec/glm::vec3 sourceCasterVec/g
            s/glm::dvec3 casterPositionVec/glm::vec3 casterPositionVec/g
            
            # Change _localTransform type
            s/glm::dmat4 _localTransform/glm::mat4 _localTransform/g
        ' "$file"
        
        rm -f "${file}.tmp"
    fi
done

echo -e "\n${GREEN}=== Additional C++ Casting Patterns ===${NC}"

# Second pass for more complex patterns
for file in $cpp_files; do
    if [ -f "$file" ]; then
        # Additional patterns that need special handling
        sed -i.tmp '
            # Cast static_cast around dmat4/mat4 operations
            s/setUniform(\([^,]*\), static_cast<glm::mat4>(\([^)]*\)) \* static_cast<glm::mat4>(\([^)]*\)))/setUniform(\1, (static_cast<glm::mat4>(\2) * static_cast<glm::mat4>(\3)))/g
            
            # Handle shadowMatrix casts
            s/shadowData\.shadowMatrix \* modelTransform/(static_cast<glm::mat4>(shadowData.shadowMatrix) * static_cast<glm::mat4>(modelTransform))/g
            
            # Cast modelTransform in general matrix operations
            s/\([^a-zA-Z_]\)modelTransform \* /\1static_cast<glm::mat4>(modelTransform) * /g
        ' "$file"
        
        rm -f "${file}.tmp"
    fi
done

echo -e "\n${GREEN}=== Summary ===${NC}"
echo "Processed files:"
echo "  - Shader files: $(echo "$shader_files" | wc -l)"
echo "  - C++ source files: $(echo "$cpp_files" | wc -l)"
echo "  - Header files: $(echo "$header_files" | wc -l)"
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
