# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Transit
  module Marshaler

    # @api private
    module JsonBase
      def initialize(io, opts)
        parse_options(opts)
      end
    end

    # @api private
    class Json
      include Transit::Marshaler::Base
      include Transit::Marshaler::JsonBase
    end

    # @api private
    class VerboseJson
      include Transit::Marshaler::Base
      include Transit::Marshaler::JsonBase
      include Transit::Marshaler::VerboseHandlers
    end
  end
end
