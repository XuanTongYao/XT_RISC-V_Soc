pub mod register {
    #![deny(missing_docs)]

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
                pub const unsafe fn from_bits(bits: $P) -> Self {
                    Self(bits)
                }
                pub const fn into_bits(&self) -> $P {
                    self.0
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
