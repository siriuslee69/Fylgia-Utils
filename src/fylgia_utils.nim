# ==================================================
# | Fylgia Utils Root Module                      |
# |------------------------------------------------|
# | Aggregates utility modules (no app backend). |
# ==================================================

const FylgiaUtilsVersion* = "0.1.0"

import fylgia_utils/level1/byte_utils
import fylgia_utils/level1/base64_utils
import fylgia_utils/level1/json_utils
import fylgia_utils/level1/time_utils
import fylgia_utils/level1/id_utils
import fylgia_utils/level1/text_validation
import fylgia_utils/level2/text_profiles
import fylgia_utils/level2/limit_defaults

export byte_utils
export base64_utils
export json_utils
export time_utils
export id_utils
export text_validation
export text_profiles
export limit_defaults
