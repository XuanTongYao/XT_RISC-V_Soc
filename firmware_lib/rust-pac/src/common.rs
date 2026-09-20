pub mod register {

    use vcell::VolatileCell;

    /// Read-Only register
    ///
    /// `default sw = r;`
    #[repr(transparent)]
    pub struct RO<T: Copy>(VolatileCell<T>);
    impl<T: Copy> RO<T> {
        /// Reads the value of the register
        #[inline(always)]
        pub fn read(&self) -> T {
            self.0.get()
        }
    }

    /// Write-Only register
    ///
    /// `default sw = w;`
    pub struct WO<T: Copy>(VolatileCell<T>);
    impl<T: Copy> WO<T> {
        /// Writes `value` into the register
        #[inline(always)]
        pub fn write(&self, value: T) {
            self.0.set(value)
        }
    }

    /// Read-Write register
    ///
    /// `default sw = rw;`/`default sw = wr;`
    pub struct RW<T: Copy>(VolatileCell<T>);
    impl<T: Copy> RW<T> {
        /// Reads the value of the register
        #[inline(always)]
        pub fn read(&self) -> T {
            self.0.get()
        }

        /// Writes `value` into the register
        #[inline(always)]
        pub fn write(&self, value: T) {
            self.0.set(value)
        }

        /// Performs a read-modify-write operation
        pub fn modify<F: FnOnce(T) -> T>(&self, f: F) {
            self.0.set(f(self.0.get()));
        }
    }

    macro_rules! bitfield_reg {
        ($B:ty,$P:ty,$RESET:literal) => {
            impl $B {
                pub const RESET: $P = $RESET;
                #[inline(always)]
                pub const fn from_bits(bits: $P) -> Self {
                    Self(bits)
                }
                #[inline(always)]
                pub const fn into_bits(self) -> $P {
                    self.0
                }
                #[inline(always)]
                pub const fn new() -> Self {
                    Self(Self::RESET)
                }
            }
            impl Default for $B {
                #[inline(always)]
                fn default() -> Self {
                    Self::new()
                }
            }

            impl From<$P> for $B {
                #[inline(always)]
                fn from(value: $P) -> Self {
                    Self::from_bits(value)
                }
            }
            impl Into<$P> for $B {
                #[inline(always)]
                fn into(self) -> $P {
                    self.into_bits()
                }
            }

            impl core::ops::BitOr for $B {
                type Output = Self;

                fn bitor(self, rhs: Self) -> Self::Output {
                    Self(self.0 | rhs.0)
                }
            }
            impl core::ops::BitAnd for $B {
                type Output = Self;

                fn bitand(self, rhs: Self) -> Self::Output {
                    Self(self.0 & rhs.0)
                }
            }
            impl core::ops::BitXor for $B {
                type Output = Self;

                fn bitxor(self, rhs: Self) -> Self::Output {
                    Self(self.0 ^ rhs.0)
                }
            }
        };
    }

    pub(crate) use bitfield_reg;

    pub struct RegisterBlock<T>(*mut T);
    impl<T> RegisterBlock<T> {
        #[inline(always)]
        pub const unsafe fn from_ptr(ptr: *mut u8) -> Self {
            Self { 0: ptr as _ }
        }
        #[inline(always)]
        pub const fn as_ptr(&self) -> *mut u8 {
            self.0 as _
        }
        #[inline(always)]
        pub const fn regs(&self) -> &'static T {
            unsafe { &*self.0 }
        }
    }
}
