module Geo3d
  class Matrix
     def remove_translation_component()
      m = self.dup
      m._41 = m._42 = m._43 = 0.0
      m 
    end

    def to_s_round(digits=2)
      (0..3).to_a.map { |i| 
        row(i).to_s_round(digits)
      }.join "\n"
    end
 
    def * v
       result = nil

      if Vector == v.class
        vec = v
        transformed_vector = Vector.new
        transformed_vector.x = _11 * vec.x + _21 * vec.y + _31 * vec.z + _41 * vec.w
        transformed_vector.y = _12 * vec.x + _22 * vec.y + _32 * vec.z + _42 * vec.w
        transformed_vector.z = _13 * vec.x + _23 * vec.y + _33 * vec.z + _43 * vec.w
        transformed_vector.w = _14 * vec.x + _24 * vec.y + _34 * vec.z + _44 * vec.w
        return transformed_vector

      elsif self.class == v.class
        result = self.class.new
        matrix = v

        result._11 = _11 * matrix._11 + _12 * matrix._21 + _13 * matrix._31 + _14 * matrix._41
        result._12 = _11 * matrix._12 + _12 * matrix._22 + _13 * matrix._32 + _14 * matrix._42
        result._13 = _11 * matrix._13 + _12 * matrix._23 + _13 * matrix._33 + _14 * matrix._43
        result._14 = _11 * matrix._14 + _12 * matrix._24 + _13 * matrix._34 + _14 * matrix._44

        result._21 = _21 * matrix._11 + _22 * matrix._21 + _23 * matrix._31 + _24 * matrix._41
        result._22 = _21 * matrix._12 + _22 * matrix._22 + _23 * matrix._32 + _24 * matrix._42
        result._23 = _21 * matrix._13 + _22 * matrix._23 + _23 * matrix._33 + _24 * matrix._43
        result._24 = _21 * matrix._14 + _22 * matrix._24 + _23 * matrix._34 + _24 * matrix._44

        result._31 = _31 * matrix._11 + _32 * matrix._21 + _33 * matrix._31 + _34 * matrix._41
        result._32 = _31 * matrix._12 + _32 * matrix._22 + _33 * matrix._32 + _34 * matrix._42
        result._33 = _31 * matrix._13 + _32 * matrix._23 + _33 * matrix._33 + _34 * matrix._43
        result._34 = _31 * matrix._14 + _32 * matrix._24 + _33 * matrix._34 + _34 * matrix._44

        result._41 = _41 * matrix._11 + _42 * matrix._21 + _43 * matrix._31 + _44 * matrix._41
        result._42 = _41 * matrix._12 + _42 * matrix._22 + _43 * matrix._32 + _44 * matrix._42
        result._43 = _41 * matrix._13 + _42 * matrix._23 + _43 * matrix._33 + _44 * matrix._43
        result._44 = _41 * matrix._14 + _42 * matrix._24 + _43 * matrix._34 + _44 * matrix._44

      elsif Triangle == v.class
        tri = v
        transformed_tri = Triangle.new
        transformed_tri.a = self * tri.a
        transformed_tri.b = self * tri.b
        transformed_tri.c = self * tri.c
        return transformed_tri
      elsif Array == v.class
        return v.map { |i| self * i }
      else
        result = self.class.new
        scalar = v
        result._11 = _11 * scalar
        result._12 = _12 * scalar
        result._13 = _13 * scalar
        result._14 = _14 * scalar
        result._21 = _21 * scalar
        result._22 = _22 * scalar
        result._23 = _23 * scalar
        result._24 = _24 * scalar
        result._31 = _31 * scalar
        result._32 = _32 * scalar
        result._33 = _33 * scalar
        result._34 = _34 * scalar
        result._41 = _41 * scalar
        result._42 = _42 * scalar
        result._43 = _43 * scalar
        result._44 = _44 * scalar
      end

      result
    end
  end
end

