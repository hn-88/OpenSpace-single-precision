ChatGPT says:

a focused, safe patch that:

Adds helpers to `ghoul/src/opengl/uniform_conversion.h` to convert double attribute values to floats (scalars, vectors, and matrix columns).

Rewrites the setAttribute implementations in `ghoul/src/opengl/programobject.cpp` so they never call glVertexAttribL* or glVertexAttribL*dv (double-precision attribute APIs). Instead they convert to floats and call the float glVertexAttrib* variants (or the existing setAttribute(location, glm::vecN) matrix branches).

Keeps everything else intact and minimal.

Apply this patch from the repository root with:

`git apply patchfilename.patch`


(or save and inspect before applying if you prefer).
