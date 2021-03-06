/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class sun_nio_ch_IOUtil */

#ifndef _Included_sun_nio_ch_IOUtil
#define _Included_sun_nio_ch_IOUtil
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    randomBytes
 * Signature: ([B)Z
 */
JNIEXPORT jboolean JNICALL Java_sun_nio_ch_IOUtil_randomBytes
  (JNIEnv *, jclass, jbyteArray);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    makePipe
 * Signature: (Z)J
 */
JNIEXPORT jlong JNICALL Java_sun_nio_ch_IOUtil_makePipe
  (JNIEnv *, jclass, jboolean);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    drain
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_sun_nio_ch_IOUtil_drain
  (JNIEnv *, jclass, jint);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    configureBlocking
 * Signature: (Ljava/io/FileDescriptor;Z)V
 */
JNIEXPORT void JNICALL Java_sun_nio_ch_IOUtil_configureBlocking
  (JNIEnv *, jclass, jobject, jboolean);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    fdVal
 * Signature: (Ljava/io/FileDescriptor;)I
 */
JNIEXPORT jint JNICALL Java_sun_nio_ch_IOUtil_fdVal
  (JNIEnv *, jclass, jobject);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    setfdVal
 * Signature: (Ljava/io/FileDescriptor;I)V
 */
JNIEXPORT void JNICALL Java_sun_nio_ch_IOUtil_setfdVal
  (JNIEnv *, jclass, jobject, jint);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    iovMax
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_sun_nio_ch_IOUtil_iovMax
  (JNIEnv *, jclass);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    fdLimit
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_sun_nio_ch_IOUtil_fdLimit
  (JNIEnv *, jclass);

/*
 * Class:     sun_nio_ch_IOUtil
 * Method:    initIDs
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_sun_nio_ch_IOUtil_initIDs
  (JNIEnv *, jclass);

#ifdef __cplusplus
}
#endif
#endif
