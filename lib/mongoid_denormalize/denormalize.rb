# encoding: UTF-8
module MongoidDenormalize
  module Denormalize
    extend ActiveSupport::Concern

    module ClassMethods

      # denormalize_field :vendor, from: :car_model
      # denormalize_field :vendor, from: :car_model, as: :some_field_name
      # denormalize_field :abc_def, from: :car_model, method: :to_s
      # denormalize_field(:model) { car_model.try(:model) }
      def denormalize_field(field_name, options = {}, &block)
        from = options.delete(:from)
        full_field_name = options.delete(:as)

        method_name = options.delete(:method)
        method_name_for_retrieving_value = method_name || field_name
        full_field_name = field_name if method_name.present?

        options[:type] ||= String

        full_field_name ||= "#{from ? from.to_s + '_' : nil}#{field_name}"

        field full_field_name, options

        generated_method_name = "_generated_#{full_field_name}"
        generated_method = define_method generated_method_name, ->{
          self[full_field_name] = if block
                                    instance_eval &block
                                  else
                                    self.try(from).try(method_name_for_retrieving_value)
                                  end
          nil
        }

        before_save generated_method_name
        private generated_method_name
      end
    end
  end
end
