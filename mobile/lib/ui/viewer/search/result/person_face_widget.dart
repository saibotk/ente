import "dart:developer";
import "dart:io";
import "dart:typed_data";

import 'package:flutter/widgets.dart';
import "package:photos/db/files_db.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/face.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import "package:photos/ui/viewer/people/cropped_face_image_view.dart";
import "package:photos/utils/face/face_box_crop.dart";
import "package:photos/utils/thumbnail_util.dart";

class PersonFaceWidget extends StatelessWidget {
  final EnteFile file;
  final String? personId;
  final int? clusterID;

  // PersonFaceWidget constructor checks that both personId and clusterID are not null
  // and that the file is not null
  const PersonFaceWidget(
    this.file, {
    this.personId,
    this.clusterID,
    Key? key,
  })  : assert(personId != null || clusterID != null,
            "PersonFaceWidget requires either personId or clusterID to be non-null"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isAndroid) {
      return FutureBuilder<Uint8List?>(
        future: getFaceCrop(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final ImageProvider imageProvider = MemoryImage(snapshot.data!);
            return Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ],
            );
          } else {
            if (snapshot.hasError) {
              log('Error getting cover face for person: ${snapshot.error}');
            }
            return ThumbnailWidget(
              file,
            );
          }
        },
      );
    } else {
      return FutureBuilder<Face?>(
        future: _getFace(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Face face = snapshot.data!;
            return Stack(
              fit: StackFit.expand,
              children: [
                CroppedFaceImageView(enteFile: file, face: face),
              ],
            );
          } else {
            if (snapshot.hasError) {
              log('Error getting cover face for person: ${snapshot.error}');
            }
            return ThumbnailWidget(
              file,
            );
          }
        },
      );
    }
  }

  Future<Face?> _getFace() async {
    String? personAvatarFaceID;
    if (personId != null) {
      PersonEntity? personEntity =
          await PersonService.instance.getPerson(personId!);
      if (personEntity != null) {
        personAvatarFaceID = personEntity.data.avatarFaceId;
      }
    }
    return await FaceMLDataDB.instance.getCoverFaceForPerson(
      recentFileID: file.uploadedFileID!,
      personAvatorFaceID: personAvatarFaceID,
      personID: personId,
      clusterID: clusterID,
    );
  }

  Future<Uint8List?> getFaceCrop() async {
    try {
      final Face? face = await _getFace();
      if (face == null) {
        debugPrint(
          "No cover face for person: $personId and cluster $clusterID and recentFile ${file.uploadedFileID}",
        );
        return null;
      }
      final Uint8List? cachedFace = faceCropCache.get(face.faceID);
      if (cachedFace != null) {
        return cachedFace;
      }
      final faceCropCacheFile = cachedFaceCropPath(face.faceID);
      if ((await faceCropCacheFile.exists())) {
        final data = await faceCropCacheFile.readAsBytes();
        faceCropCache.put(face.faceID, data);
        return data;
      }
      EnteFile? fileForFaceCrop = file;
      if (face.fileID != file.uploadedFileID!) {
        fileForFaceCrop =
            await FilesDB.instance.getAnyUploadedFile(face.fileID);
      }
      if (fileForFaceCrop == null) {
        return null;
      }

      final result = await pool.withResource(
        () async => await getFaceCrops(
          fileForFaceCrop!,
          {
            face.faceID: face.detection.box,
          },
        ),
      );
      final Uint8List? computedCrop = result?[face.faceID];
      if (computedCrop != null) {
        faceCropCache.put(face.faceID, computedCrop);
        faceCropCacheFile.writeAsBytes(computedCrop).ignore();
      }
      return computedCrop;
    } catch (e, s) {
      log(
        "Error getting cover face for person: $personId and cluster $clusterID",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
