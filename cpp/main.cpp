// Minimal SketchUp C API declarations used by this converter.
// This intentionally avoids depending on SDK headers when only the framework is
// available. Keep these declarations limited to the functions/types used below.

typedef int SUResult;

const SUResult SU_ERROR_NONE = 0;

struct SUModelRef {
  void* ptr;
};
const SUModelRef SU_INVALID = { 0 };

enum SUModelLoadStatus {
  SUModelLoadStatus_Success = 0,
  SUModelLoadStatus_Success_MoreRecent = 1
};

enum SUModelVersion {
  SUModelVersion_SU3 = 0,
  SUModelVersion_SU4,
  SUModelVersion_SU5,
  SUModelVersion_SU6,
  SUModelVersion_SU7,
  SUModelVersion_SU8,
  SUModelVersion_SU2013,
  SUModelVersion_SU2014,
  SUModelVersion_SU2015,
  SUModelVersion_SU2016,
  SUModelVersion_SU2017,
  SUModelVersion_SU2018,
  SUModelVersion_SU2019,
  SUModelVersion_SU2020,
  SUModelVersion_SU2021
};

extern "C" void SUInitialize();
extern "C" void SUTerminate();
extern "C" SUResult SUModelCreateFromFileWithStatus(
    SUModelRef* model, const char* file_path, SUModelLoadStatus* load_status);
extern "C" SUResult SUModelSaveToFileWithVersion(
    SUModelRef model, const char* file_path, SUModelVersion version);
extern "C" SUResult SUModelRelease(SUModelRef* model);
#include <cstdlib>

SUModelVersion version_from_name(int version_name) {
  switch (version_name) {
    case 3: return SUModelVersion_SU3;
    case 4: return SUModelVersion_SU4;
    case 5: return SUModelVersion_SU5;
    case 6: return SUModelVersion_SU6;
    case 7: return SUModelVersion_SU7;
    case 8: return SUModelVersion_SU8;
    case 13: return SUModelVersion_SU2013;
    case 14: return SUModelVersion_SU2014;
    case 15: return SUModelVersion_SU2015;
    case 16: return SUModelVersion_SU2016;
    case 17: return SUModelVersion_SU2017;
    case 18: return SUModelVersion_SU2018;
    case 19: return SUModelVersion_SU2019;
    case 20: return SUModelVersion_SU2020;
    case 21: return SUModelVersion_SU2021;
    default: return static_cast<SUModelVersion>(-1);
  }
}

// - Source path
// - Target path
// - SketchUp version (without leading 20)
int main(int argc, char* argv[]) {
  if (argc != 4) return 1;

  const char* source = argv[1];
  const char* target = argv[2];
  int version_name = std::atoi(argv[3]);

  // With version 2021 SketchUp changed to a "versionless" file format,
  // meaning later application versions use the same file version.
  if (version_name > 21)
      version_name = 21;

  SUModelVersion version = version_from_name(version_name);
  if (version == static_cast<SUModelVersion>(-1)) return 2;

  SUInitialize();

  SUModelRef model = SU_INVALID;
  SUModelLoadStatus status;
  SUResult res = SUModelCreateFromFileWithStatus(&model, source, &status);
  if (res != SU_ERROR_NONE) return 1;

  res = SUModelSaveToFileWithVersion(model, target, version);
  SUModelRelease(&model);
  SUTerminate();
  return res == SU_ERROR_NONE ? 0 : 1;
}
