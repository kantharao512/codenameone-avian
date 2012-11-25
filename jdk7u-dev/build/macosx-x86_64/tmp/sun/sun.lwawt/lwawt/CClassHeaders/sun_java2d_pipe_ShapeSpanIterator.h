/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class sun_java2d_pipe_ShapeSpanIterator */

#ifndef _Included_sun_java2d_pipe_ShapeSpanIterator
#define _Included_sun_java2d_pipe_ShapeSpanIterator
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    initIDs
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_initIDs
  (JNIEnv *, jclass);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    appendPoly
 * Signature: ([I[IIII)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_appendPoly
  (JNIEnv *, jobject, jintArray, jintArray, jint, jint, jint);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    setNormalize
 * Signature: (Z)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_setNormalize
  (JNIEnv *, jobject, jboolean);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    setOutputAreaXYXY
 * Signature: (IIII)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_setOutputAreaXYXY
  (JNIEnv *, jobject, jint, jint, jint, jint);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    setRule
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_setRule
  (JNIEnv *, jobject, jint);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    addSegment
 * Signature: (I[F)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_addSegment
  (JNIEnv *, jobject, jint, jfloatArray);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    getPathBox
 * Signature: ([I)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_getPathBox
  (JNIEnv *, jobject, jintArray);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    intersectClipBox
 * Signature: (IIII)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_intersectClipBox
  (JNIEnv *, jobject, jint, jint, jint, jint);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    nextSpan
 * Signature: ([I)Z
 */
JNIEXPORT jboolean JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_nextSpan
  (JNIEnv *, jobject, jintArray);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    skipDownTo
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_skipDownTo
  (JNIEnv *, jobject, jint);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    getNativeIterator
 * Signature: ()J
 */
JNIEXPORT jlong JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_getNativeIterator
  (JNIEnv *, jobject);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    dispose
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_dispose
  (JNIEnv *, jobject);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    moveTo
 * Signature: (FF)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_moveTo
  (JNIEnv *, jobject, jfloat, jfloat);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    lineTo
 * Signature: (FF)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_lineTo
  (JNIEnv *, jobject, jfloat, jfloat);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    quadTo
 * Signature: (FFFF)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_quadTo
  (JNIEnv *, jobject, jfloat, jfloat, jfloat, jfloat);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    curveTo
 * Signature: (FFFFFF)V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_curveTo
  (JNIEnv *, jobject, jfloat, jfloat, jfloat, jfloat, jfloat, jfloat);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    closePath
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_closePath
  (JNIEnv *, jobject);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    pathDone
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_pathDone
  (JNIEnv *, jobject);

/*
 * Class:     sun_java2d_pipe_ShapeSpanIterator
 * Method:    getNativeConsumer
 * Signature: ()J
 */
JNIEXPORT jlong JNICALL Java_sun_java2d_pipe_ShapeSpanIterator_getNativeConsumer
  (JNIEnv *, jobject);

#ifdef __cplusplus
}
#endif
#endif