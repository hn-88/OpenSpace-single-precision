#include <GL/glew.h>   // If using glad, replace with <glad/glad.h>

namespace ghoul::opengl::util {

// Convert an array of GLdouble -> GLfloat
inline const GLfloat* convert(const GLdouble* src, size_t count) {
    static thread_local std::vector<GLfloat> tmp;
    if (tmp.size() < count) tmp.resize(count);
    for (size_t i = 0; i < count; ++i) {
        tmp[i] = static_cast<GLfloat>(src[i]);
    }
    return tmp.data();
}

inline void Uniform3dv(GLint loc, const GLdouble* value) {
    const GLfloat* f = convert(value, 3);
    glUniform3fv(loc, 1, f);
}

 
 inline void Uniform4dv(GLint loc, const GLdouble* value) {
     const GLfloat* f = convert(value, 4);
     glUniform4fv(loc, 1, f);
 }
 
 inline void UniformMatrix4dv(GLint loc, const GLdouble* value) {
     const GLfloat* f = convert(value, 16);
     glUniformMatrix4fv(loc, 1, GL_FALSE, f);
 }
 
 inline void UniformMatrix3dv(GLint loc, const GLdouble* value) {
     const GLfloat* f = convert(value, 9);
     glUniformMatrix3fv(loc, 1, GL_FALSE, f);
 }
 
// ---------------- Vertex attribute helpers (convert doubles -> floats) ----------------

inline void VertexAttrib1d_as_f(GLuint loc, GLdouble v) {
    glVertexAttrib1f(loc, static_cast<GLfloat>(v));
}

inline void VertexAttrib2d_as_f(GLuint loc, GLdouble v1, GLdouble v2) {
    glVertexAttrib2f(loc, static_cast<GLfloat>(v1), static_cast<GLfloat>(v2));
}

inline void VertexAttrib3d_as_f(GLuint loc, GLdouble v1, GLdouble v2, GLdouble v3) {
    glVertexAttrib3f(loc,
        static_cast<GLfloat>(v1),
        static_cast<GLfloat>(v2),
        static_cast<GLfloat>(v3)
    );
}

inline void VertexAttrib4d_as_f(GLuint loc, GLdouble v1, GLdouble v2, GLdouble v3, GLdouble v4) {
    glVertexAttrib4f(loc,
        static_cast<GLfloat>(v1),
        static_cast<GLfloat>(v2),
        static_cast<GLfloat>(v3),
        static_cast<GLfloat>(v4)
    );
}

inline void VertexAttrib2dv_as_fv(GLuint loc, const GLdouble* v) {
    const GLfloat* f = convert(v, 2);
    glVertexAttrib2fv(loc, f);
}

inline void VertexAttrib3dv_as_fv(GLuint loc, const GLdouble* v) {
    const GLfloat* f = convert(v, 3);
    glVertexAttrib3fv(loc, f);
}

inline void VertexAttrib4dv_as_fv(GLuint loc, const GLdouble* v) {
    const GLfloat* f = convert(v, 4);
    glVertexAttrib4fv(loc, f);
}

// Matrix column helpers: call columnwise float vertexAttrib*fv
inline void VertexAttribMatrix2_as_fv(GLuint loc, const GLdouble* col0, const GLdouble* col1) {
    VertexAttrib2dv_as_fv(loc + 0, col0);
    VertexAttrib2dv_as_fv(loc + 1, col1);
}

inline void VertexAttribMatrix3_as_fv(GLuint loc, const GLdouble* col0, const GLdouble* col1, const GLdouble* col2) {
    VertexAttrib3dv_as_fv(loc + 0, col0);
    VertexAttrib3dv_as_fv(loc + 1, col1);
    VertexAttrib3dv_as_fv(loc + 2, col2);
}

inline void VertexAttribMatrix4_as_fv(GLuint loc, const GLdouble* col0, const GLdouble* col1, const GLdouble* col2, const GLdouble* col3) {
    VertexAttrib4dv_as_fv(loc + 0, col0);
    VertexAttrib4dv_as_fv(loc + 1, col1);
    VertexAttrib4dv_as_fv(loc + 2, col2);
    VertexAttrib4dv_as_fv(loc + 3, col3);
}

 } // namespace ghoul::opengl::util
