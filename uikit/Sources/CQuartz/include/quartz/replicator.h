/* OWNED BY package replicator. Do not edit from other packages. */
#ifndef QUARTZ_REPLICATOR_H
#define QUARTZ_REPLICATOR_H
#ifdef __cplusplus
extern "C" {
#endif

QZLayerRef QZReplicatorLayerCreate(void);
void QZReplicatorLayerSetInstanceCount(QZLayerRef layer, int count);
void QZReplicatorLayerSetInstanceTransform(QZLayerRef layer, QZTransform3D t);
void QZReplicatorLayerSetInstanceColor(QZLayerRef layer,
                                       QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZReplicatorLayerSetInstanceRedOffset(QZLayerRef layer, QZFloat v);
void QZReplicatorLayerSetInstanceGreenOffset(QZLayerRef layer, QZFloat v);
void QZReplicatorLayerSetInstanceBlueOffset(QZLayerRef layer, QZFloat v);
void QZReplicatorLayerSetInstanceAlphaOffset(QZLayerRef layer, QZFloat v);

#ifdef __cplusplus
}
#endif
#endif
