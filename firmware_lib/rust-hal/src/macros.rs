#[macro_export]
macro_rules! bitfield_accessor {
    ($(#[$doc:meta])* unsafe $name:ident, $reg:ident, $field:ident, $t:ty, $ac:tt) => {
        $crate::bitfield_accessor!(@impl $(#[$doc])* (unsafe) $name, $reg, $field, $t, $ac);
    };
    ($(#[$doc:meta])* $name:ident, $reg:ident, $field:ident, $t:ty, $ac:tt) => {
        $crate::bitfield_accessor!(@impl $(#[$doc])* () $name, $reg, $field, $t, $ac);
    };
    (@impl $(#[$doc:meta])* ($($unsafe:tt)?) $name:ident, $reg:ident, $field:ident, $t:ty, get) => {
        $(#[$doc])*
        #[inline(always)]
        pub $($unsafe)? fn $name(&self) -> $t { self.inst.regs().$reg.read().$field() }
    };
    (@impl $(#[$doc:meta])* ($($unsafe:tt)?) $name:ident, $reg:ident, $field:ident, $t:ty, set) => {
        pastey::paste! {
            $(#[$doc])*
            #[inline(always)]
            pub $($unsafe)? fn [<set_ $name>](&mut self, value: $t) {
                self.inst.regs().$reg.modify(|reg| reg.[<with_ $field>](value))
            }
        }
    };
}

#[macro_export]
macro_rules! getset_field {
    ($(#[$doc:meta])* unsafe $name:ident, $reg:ident, $field:ident, $t:ty) => {
        $crate::bitfield_accessor!($(#[$doc])* unsafe $name, $reg, $field, $t, get);
        $crate::bitfield_accessor!($(#[$doc])* unsafe $name, $reg, $field, $t, set);
    };
    ($(#[$doc:meta])* $name:ident, $reg:ident, $field:ident, $t:ty) => {
        $crate::bitfield_accessor!($(#[$doc])* $name, $reg, $field, $t, get);
        $crate::bitfield_accessor!($(#[$doc])* $name, $reg, $field, $t, set);
    };
}

#[macro_export]
macro_rules! reg_accessor {
    ($(#[$doc:meta])* unsafe $name:ident, $reg:ident, $t:ty, $ac:tt) => {
        $crate::reg_accessor!(@impl $(#[$doc])* (unsafe) $name, $reg, $t, $ac);
    };
    ($(#[$doc:meta])* $name:ident, $reg:ident, $t:ty, $ac:tt) => {
        $crate::reg_accessor!(@impl $(#[$doc])* () $name, $reg, $t, $ac);
    };
    (@impl $(#[$doc:meta])* ($($unsafe:tt)?) $name:ident, $reg:ident, $t:ty, get) => {
        $(#[$doc])*
        #[inline(always)]
        pub $($unsafe)? fn $name(&self) -> $t { self.inst.regs().$reg.read() }
    };
    (@impl $(#[$doc:meta])* ($($unsafe:tt)?) $name:ident, $reg:ident, $t:ty, set) => {
        pastey::paste! {
            $(#[$doc])*
            #[inline(always)]
            pub $($unsafe)? fn [<set_ $name>](&mut self, value: $t) {
                self.inst.regs().$reg.write(value)
            }
        }
    };
    (@impl $(#[$doc:meta])* ($($unsafe:tt)?) $name:ident, $reg:ident, $t:ty, modify) => {
        pastey::paste! {
            $(#[$doc])*
            #[inline]
            pub $($unsafe)? fn [<modify_ $name>]<F: FnOnce($t) -> $t>(&mut self, f: F) {
                self.inst.regs().$reg.modify(f)
            }
        }
    };
}

#[macro_export]
macro_rules! prop_value {
    ($(#[$doc:meta])* unsafe $name:ident, $reg:ident, $t:ty, $($ac:tt),+) => {
        $crate::prop_value!(@impl $(#[$doc])* (unsafe) $name, $reg, $t $(, $ac)+);
    };
    ($(#[$doc:meta])* $name:ident, $reg:ident, $t:ty, $($ac:tt),+) => {
        $crate::prop_value!(@impl $(#[$doc])* () $name, $reg, $t $(, $ac)+);
    };

    (@impl $(#[$doc:meta])* ($($un:tt)?) $name:ident, $reg:ident, $t:ty, $ac:ident $(, $rest:ident)*) => {
        $crate::reg_accessor!($(#[$doc])* $($un)? $name, $reg, $t, $ac);
        $crate::prop_value!(@impl $(#[$doc])* ($($un)?) $name, $reg, $t $(, $rest)*);
    };
    (@impl $(#[$doc:meta])* ($($un:tt)?) $name:ident, $reg:ident, $t:ty) => {};
}
