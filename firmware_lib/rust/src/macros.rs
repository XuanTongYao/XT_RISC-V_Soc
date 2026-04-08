#[macro_export]
macro_rules! get_field {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            $crate::get_field!(@impl $(#[$doc])*, (unsafe), $name, $($reg)?, $field, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            $crate::get_field!(@impl $(#[$doc])*, (), $name, $($reg)?, $field, $t);
        };
        (@impl $(#[$doc:meta])*, ($($unsafe:tt)?), $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            $(#[$doc])*
            #[inline(always)]
            pub $($unsafe)? fn $name(&self) -> $t { self.reg(). $($reg.)? read().$field() }
        };
    }

#[macro_export]
macro_rules! set_field {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            $crate::set_field!(@impl $(#[$doc])*, (unsafe), $name, $($reg)?, $field, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            $crate::set_field!(@impl $(#[$doc])*, (), $name, $($reg)?, $field, $t);
        };
        (@impl $(#[$doc:meta])*, ($($unsafe:tt)?), $name:ident, $($reg:ident)?, $field:ident, $t:ty) => {
            paste::paste! {
                $(#[$doc])*
                #[inline(always)]
                pub $($unsafe)? fn [<set_ $name>](&mut self, value: $t) {
                    unsafe { self.reg(). $($reg.)? modify(|reg| reg.[<with_ $field>](value)) }
                }
            }
        };
    }

#[macro_export]
macro_rules! getset_field {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?,$field:ident,$t:ty) => {
            $crate::get_field!($(#[$doc])* unsafe $name, $($reg)?, $field, $t);
            $crate::set_field!($(#[$doc])* unsafe $name, $($reg)?, $field, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?,$field:ident,$t:ty) => {
            $crate::get_field!($(#[$doc])* $name, $($reg)?, $field, $t);
            $crate::set_field!($(#[$doc])* $name, $($reg)?, $field, $t);
        };
    }

#[macro_export]
macro_rules! get_value {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::get_value!(@impl $(#[$doc])*, (unsafe), $name, $($reg)?, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::get_value!(@impl $(#[$doc])*, (), $name, $($reg)?, $t);
        };
        (@impl $(#[$doc:meta])*, ($($unsafe:tt)?), $name:ident, $($reg:ident)?, $t:ty) => {
            $(#[$doc])*
            #[inline(always)]
            pub $($unsafe)? fn $name(&self) -> $t { self.reg(). $($reg.)? read() }
        };
    }

#[macro_export]
macro_rules! set_value {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::set_value!(@impl $(#[$doc])*, (unsafe), $name, $($reg)?, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::set_value!(@impl $(#[$doc])*, (), $name, $($reg)?, $t);
        };
        (@impl $(#[$doc:meta])*, ($($unsafe:tt)?), $name:ident, $($reg:ident)?, $t:ty) => {
            paste::paste! {
                $(#[$doc])*
                #[inline(always)]
                pub $($unsafe)? fn [<set_ $name>](&mut self, value: $t) {
                    unsafe { self.reg(). $($reg.)? write(value) }
                }
            }
        };
    }

#[macro_export]
macro_rules! getset_value {
        ($(#[$doc:meta])* unsafe $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::get_value!($(#[$doc])* unsafe $name, $($reg)?, $t);
            $crate::set_value!($(#[$doc])* unsafe $name, $($reg)?, $t);
        };
        ($(#[$doc:meta])* $name:ident, $($reg:ident)?, $t:ty) => {
            $crate::get_value!($(#[$doc])* $name, $($reg)?, $t);
            $crate::set_value!($(#[$doc])* $name, $($reg)?, $t);
        };
    }
