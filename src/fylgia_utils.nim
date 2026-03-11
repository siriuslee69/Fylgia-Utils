# ==================================================
# | Fylgia Utils Root Module                      |
# |------------------------------------------------|
# | Aggregates utility modules (no app backend). |
# ==================================================

const FylgiaUtilsVersion* = "0.1.0"

import fylgia_utils/io/byte_utils
import fylgia_utils/io/base64_utils
import fylgia_utils/io/config_io
import fylgia_utils/io/json_utils
import fylgia_utils/time/time_utils
import fylgia_utils/identity/id_utils
import fylgia_utils/validation/text_validation
import fylgia_utils/text_query/ops
import fylgia_utils/validation/text_profiles
import fylgia_utils/validation/limit_defaults

export byte_utils
export base64_utils
export config_io
export json_utils
export time_utils
export id_utils
export text_validation
export ops
export text_profiles
export limit_defaults
