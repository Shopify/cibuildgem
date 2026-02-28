# frozen_string_literal: true

require "rake/extensiontask"

module Cibuildgem
  module ExtensionPatch
    class << self
      def prepended(mod)
        class << mod
          attr_accessor :enabled, :current

          def enable!
            @enabled = true
          end
        end
      end
    end

    def initialize(*)
      super

      self.class.current = self
    end

    def define
      super if self.class.enabled
    end
  end
end

Rake::ExtensionTask.prepend(Cibuildgem::ExtensionPatch)
