pub trait DirectionType {
    fn new_from(d: DynDirection) -> Self;
    fn as_dyn(&self) -> DynDirection;
}

pub trait AltFunctionType {
    fn new_from(d: DynAltFunction) -> Self;
    fn as_dyn(&self) -> DynAltFunction;
}

macro_rules! enum_dyn_type {
    (($enum:ident, $trait:ty), $($name:tt),*) => {
        #[derive(Clone, Copy, Debug, PartialEq, Eq)]
        pub enum $enum {
            $( $name, )*
        }
        impl $trait for $enum {
            fn new_from(d: $enum) -> Self {
                d
            }
            fn as_dyn(&self) -> $enum {
                *self
            }
        }
        $(
            pub struct $name;
            impl $trait for $name{
                fn new_from(_: $enum) -> Self {
                    Self{}
                }
                fn as_dyn(&self) -> $enum {
                    $enum::$name
                }
            }
        )*
    };
}

/// 最多允许`0..=31`共32个引脚ID
pub trait PinId: Copy + Clone {
    /// 返回`ID`对应的整数值
    fn id(&self) -> u8;
    /// 返回`bit[ID] = 0b1`对应的掩码
    fn mask(&self) -> u32 {
        0x1 << self.id()
    }
}

macro_rules! pin_ids {
    ($($id:literal),*) => {
        pastey::paste!{
            $(
                #[derive(Copy,Clone)]
                pub struct [<PinId $id>];
                impl PinId for [<PinId $id>] {
                    fn id(&self) -> u8 {
                        $id
                    }
                }
            )*
        }
    };
}

pin_ids!(
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    26, 27, 28, 29, 30, 31
);

impl PinId for u8 {
    fn id(&self) -> u8 {
        *self
    }
}

macro_rules! pins {
    ($prefix:ident, $getter:ty, $reset_dir:ty, $reset_af:ty, $($id:literal),*) => {
        pastey::paste!{
            use $crate::gpio::{$([<PinId $id>] ,)*};
            pub struct [<$prefix Pins>] {
                $(pub [<io $id>]: Pin<$getter, [<PinId $id>], $reset_dir, $reset_af>,)*
            }
            impl [<$prefix Pins>] {
                fn new() -> Self {
                    Self {
                        $(
                            [<io $id>]: Pin::new([<PinId $id>], $reset_dir, $reset_af),
                        )*
                    }
                }
            }
        }
    };
}

enum_dyn_type!((DynDirection, DirectionType), Input, Output);

enum_dyn_type!(
    (DynAltFunction, AltFunctionType),
    Af0,
    Af1,
    Af2,
    Af3,
    DisableAf
);
pub trait SomeAltFunction: AltFunctionType {}
impl SomeAltFunction for Af0 {}
impl SomeAltFunction for Af1 {}
impl SomeAltFunction for Af2 {}
impl SomeAltFunction for Af3 {}

use core::marker::PhantomData;

use embedded_hal::digital::{InputPin, OutputPin, PinState, StatefulOutputPin};
pub(crate) use pins;

pub trait IoController {
    fn set_direction(&mut self, mask: u32, direction: DynDirection);
    fn set_alt_function(&mut self, mask: u32, alt_func: DynAltFunction);
    fn set_state(&mut self, mask: u32, state: PinState);
    fn get_all_state(&self) -> u32;

    #[inline]
    fn set_id_direction<T: PinId>(&mut self, id: T, direction: DynDirection) {
        self.set_direction(id.mask(), direction)
    }
    #[inline]
    fn set_id_alt_function<T: PinId>(&mut self, id: T, alt_func: DynAltFunction) {
        self.set_alt_function(id.mask(), alt_func)
    }
    #[inline]
    fn set_id_state<T: PinId>(&mut self, id: T, state: PinState) {
        self.set_state(id.mask(), state)
    }
}

pub struct CtrlGetterGuard(());
pub trait CtrlGetter {
    /// 返回IO控制器
    ///
    /// 如果一定要按照官方HAL的做法把Pin作为独立对象使用的话，不可避免存在并发问题
    /// # NOTE
    /// 如果在硬件底层分解成 Clear & Set 寄存器，或许可以解决并发问题
    fn ctrl(_: CtrlGetterGuard) -> impl IoController;
}

pub struct Pin<
    Getter: CtrlGetter,
    Id: PinId,
    Direction: DirectionType,
    AltFunction: AltFunctionType,
> {
    ctrl_getter: PhantomData<Getter>,
    pub(crate) id: Id,
    pub(crate) dir: Direction,
    pub(crate) alt_func: AltFunction,
}

impl<Getter: CtrlGetter, Id: PinId, Direction: DirectionType, Af: AltFunctionType>
    Pin<Getter, Id, Direction, Af>
{
    pub(crate) fn new(id: Id, dir: Direction, alt_func: Af) -> Self {
        Self {
            ctrl_getter: PhantomData,
            id,
            dir,
            alt_func,
        }
    }

    fn ctrl() -> impl IoController {
        Getter::ctrl(CtrlGetterGuard(()))
    }

    /// # Safety
    /// 不修改实际寄存器的状态，强制更改引脚类型
    pub unsafe fn into_unchecked<NewDir: DirectionType, NewAf: AltFunctionType>(
        self,
    ) -> Pin<Getter, Id, NewDir, NewAf> {
        Pin {
            ctrl_getter: PhantomData,
            id: self.id,
            dir: NewDir::new_from(self.dir.as_dyn()),
            alt_func: NewAf::new_from(self.alt_func.as_dyn()),
        }
    }

    pub fn into_dyn_pin(self) -> Pin<Getter, u8, Direction, Af> {
        Pin {
            ctrl_getter: PhantomData,
            id: self.id.id(),
            dir: self.dir,
            alt_func: self.alt_func,
        }
    }
}

/// 输入模式的类型
impl<Getter: CtrlGetter, Id: PinId, Af: AltFunctionType> Pin<Getter, Id, Input, Af> {
    pub fn into_output(self) -> Pin<Getter, Id, Output, Af> {
        Self::ctrl().set_id_direction(self.id, DynDirection::Output);
        Pin {
            ctrl_getter: PhantomData,
            id: self.id,
            dir: Output,
            alt_func: self.alt_func,
        }
    }
}

/// 输出模式的类型
impl<Getter: CtrlGetter, Id: PinId, Af: AltFunctionType> Pin<Getter, Id, Output, Af> {
    pub fn into_input(self) -> Pin<Getter, Id, Input, Af> {
        Self::ctrl().set_id_direction(self.id, DynDirection::Input);
        Pin {
            ctrl_getter: PhantomData,
            id: self.id,
            dir: Input,
            alt_func: self.alt_func,
        }
    }
}

/// 关闭了复用功能的类型
impl<Getter: CtrlGetter, Id: PinId, Direction: DirectionType>
    Pin<Getter, Id, Direction, DisableAf>
{
    pub fn into_alt_funct<Af: SomeAltFunction>(self) -> Pin<Getter, Id, Direction, Af> {
        let prev = self.alt_func.as_dyn();
        let alt_funct = Af::new_from(prev);
        let new = alt_funct.as_dyn();

        if prev != new {
            Self::ctrl().set_id_alt_function(self.id, new);
        }

        Pin {
            ctrl_getter: PhantomData,
            id: self.id,
            dir: self.dir,
            alt_func: alt_funct,
        }
    }
}

/// 开启了复用功能的类型
impl<Getter: CtrlGetter, Id: PinId, Direction: DirectionType, Af: SomeAltFunction>
    Pin<Getter, Id, Direction, Af>
{
    pub fn into_alt_funct_disabled(self) -> Pin<Getter, Id, Direction, DisableAf> {
        Self::ctrl().set_id_alt_function(self.id, DynAltFunction::DisableAf);
        Pin {
            ctrl_getter: PhantomData,
            id: self.id,
            dir: self.dir,
            alt_func: DisableAf,
        }
    }
}

impl<Getter: CtrlGetter, Id: PinId, Direction: DirectionType, AltFunction: AltFunctionType>
    embedded_hal::digital::ErrorType for Pin<Getter, Id, Direction, AltFunction>
{
    type Error = !;
}

impl<Getter: CtrlGetter, Id: PinId> InputPin for Pin<Getter, Id, Input, DisableAf> {
    fn is_high(&mut self) -> Result<bool, Self::Error> {
        Ok(Self::ctrl().get_all_state() & self.id.mask() != 0)
    }

    fn is_low(&mut self) -> Result<bool, Self::Error> {
        Ok(Self::ctrl().get_all_state() & self.id.mask() == 0)
    }
}

impl<Getter: CtrlGetter, Id: PinId> OutputPin for Pin<Getter, Id, Output, DisableAf> {
    fn set_low(&mut self) -> Result<(), Self::Error> {
        Self::ctrl().set_id_state(self.id, PinState::Low);
        Ok(())
    }

    fn set_high(&mut self) -> Result<(), Self::Error> {
        Self::ctrl().set_id_state(self.id, PinState::High);
        Ok(())
    }
}

impl<Getter: CtrlGetter, Id: PinId> StatefulOutputPin for Pin<Getter, Id, Output, DisableAf> {
    fn is_set_high(&mut self) -> Result<bool, Self::Error> {
        Ok(Self::ctrl().get_all_state() & self.id.mask() != 0)
    }

    fn is_set_low(&mut self) -> Result<bool, Self::Error> {
        Ok(Self::ctrl().get_all_state() & self.id.mask() == 0)
    }
}

// -----------------------------------------
// 下面全都是批量设置的
//
pub struct BatchesGuard(());

pub trait IntoDirectionInBatches<NewDir: DirectionType> {
    type Output;
    fn into_direction(self, _: BatchesGuard) -> Self::Output;
}
pub trait IntoAltFunctInBatches<NewAf: AltFunctionType> {
    type Output;
    fn into_alt(self, _: BatchesGuard) -> Self::Output;
}
pub trait IntoDynPinInBatches {
    type Output;
    fn into_dyn(self, _: BatchesGuard) -> Self::Output;
}
pub trait SetPinStateInBatches {
    fn set_pin_state(&mut self, _: BatchesGuard, state: PinState);
}

macro_rules! impl_batch {
    (dir, $($i:tt),*) => { pastey::paste! {
        impl<NewDir, Getter, $([<Id$i>], [<Dir$i>], [<Af$i>]),*> IntoDirectionInBatches<NewDir>
            for ($(Pin<Getter, [<Id$i>], [<Dir$i>], [<Af$i>]>,)*)
        where NewDir: DirectionType, Getter: CtrlGetter,
            $([<Id$i>]: PinId, [<Dir$i>]: DirectionType, [<Af$i>]: AltFunctionType,)*
        {
            type Output = ($(Pin<Getter, [<Id$i>], NewDir, [<Af$i>]>,)*);
            fn into_direction(self, _: BatchesGuard) -> Self::Output {
                let mask = 0u32 $(| self.$i.id.mask())*;
                let d = NewDir::new_from(DynDirection::Input).as_dyn();
                Getter::ctrl(CtrlGetterGuard(())).set_direction(mask, d);
                ($(Pin { ctrl_getter: core::marker::PhantomData, id: self.$i.id,
                    dir: NewDir::new_from(self.$i.dir.as_dyn()), alt_func: self.$i.alt_func },)*)
            }
        }
    }};
    (alt, $($i:tt),*) => { pastey::paste! {
        impl<NewAf, Getter, $([<Id$i>], [<Dir$i>], [<Af$i>]),*> IntoAltFunctInBatches<NewAf>
            for ($(Pin<Getter, [<Id$i>], [<Dir$i>], [<Af$i>]>,)*)
        where NewAf: AltFunctionType, Getter: CtrlGetter,
            $([<Id$i>]: PinId, [<Dir$i>]: DirectionType, [<Af$i>]: AltFunctionType,)*
        {
            type Output = ($(Pin<Getter, [<Id$i>], [<Dir$i>], NewAf>,)*);
            fn into_alt(self, _: BatchesGuard) -> Self::Output {
                let mask = 0u32 $(| self.$i.id.mask())*;
                let a = NewAf::new_from(DynAltFunction::DisableAf).as_dyn();
                Getter::ctrl(CtrlGetterGuard(())).set_alt_function(mask, a);
                ($(Pin { ctrl_getter: core::marker::PhantomData, id: self.$i.id,
                    dir: self.$i.dir, alt_func: NewAf::new_from(self.$i.alt_func.as_dyn()) },)*)
            }
        }
    }};
    (state, $($i:tt),*) => { pastey::paste! {
        impl<Getter, $([<Id$i>]),*> SetPinStateInBatches
            for ($(Pin<Getter, [<Id$i>], Output, DisableAf>,)*)
        where Getter: CtrlGetter, $([<Id$i>]: PinId,)*
        {
            fn set_pin_state(&mut self, _: BatchesGuard, state: PinState) {
                let mask = 0u32 $(| self.$i.id.mask())*;
                Getter::ctrl(CtrlGetterGuard(())).set_state(mask, state);
            }
        }
    }};
    (dyn, $($i:tt),*) => { pastey::paste! {
        impl<Getter, $([<Id$i>], [<Dir$i>], [<Af$i>]),*> IntoDynPinInBatches
            for ($(Pin<Getter, [<Id$i>], [<Dir$i>], [<Af$i>]>,)*)
        where Getter: CtrlGetter, $([<Id$i>]: PinId, [<Dir$i>]: DirectionType, [<Af$i>]: AltFunctionType,)*
        {
            type Output = ($(Pin<Getter, u8, [<Dir$i>], [<Af$i>]>,)*);
            fn into_dyn(self, _: BatchesGuard) -> Self::Output {
                ($(Pin { ctrl_getter: core::marker::PhantomData, id: self.$i.id.id(),
                    dir: self.$i.dir, alt_func: self.$i.alt_func },)*)
            }
        }
    }};
}

macro_rules! gen_1_to_32 {
    () => { gen_1_to_32!(@p (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)); };
    (@p ($h:tt $($t:tt)*)) => { gen_1_to_32!(@b ($h) $($t)*); };
    (@b ($($b:tt)*) $h:tt $($t:tt)*) => {
        impl_batch!(dir, $($b),*); impl_batch!(alt, $($b),*);
        impl_batch!(state, $($b),*); impl_batch!(dyn, $($b),*);
        gen_1_to_32!(@b ($($b)* $h) $($t)*);
    };
    (@b ($($b:tt)*)) => {
        impl_batch!(dir, $($b),*); impl_batch!(alt, $($b),*);
        impl_batch!(state, $($b),*); impl_batch!(dyn, $($b),*);
    };
}
gen_1_to_32!();

pub fn into_direction_in_batches<NewDir: DirectionType, T: IntoDirectionInBatches<NewDir>>(
    p: T,
) -> T::Output {
    p.into_direction(BatchesGuard(()))
}
pub fn into_alt_funct_in_batches<NewAf: AltFunctionType, T: IntoAltFunctInBatches<NewAf>>(
    p: T,
) -> T::Output {
    p.into_alt(BatchesGuard(()))
}
pub fn into_dyn_pin_in_batches<T: IntoDynPinInBatches>(p: T) -> T::Output {
    p.into_dyn(BatchesGuard(()))
}
pub fn set_pin_state_in_batches<T: SetPinStateInBatches>(p: &mut T, state: PinState) {
    p.set_pin_state(BatchesGuard(()), state)
}
