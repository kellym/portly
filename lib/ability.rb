module Ability
  def can?(action)
    case action.to_sym
    when :mirror
      !self.plan.free?
    else
      true
    end
  end
end
