use proc_macro::TokenStream;
use quote::quote;
use syn::{ItemFn, ReturnType, Type, parse_macro_input, parse_quote, spanned::Spanned};

#[proc_macro_attribute]
pub fn entry(_args: TokenStream, input: TokenStream) -> TokenStream {
    let mut f = parse_macro_input!(input as ItemFn);

    // 检查：1. 无参数  2. 无泛型  3. 返回类型必须是 Type::Never (!)
    let is_valid_signature = f.sig.inputs.is_empty()
        && f.sig.generics.params.is_empty()
        && matches!(f.sig.output, ReturnType::Type(_, ref ty) if matches!(**ty, Type::Never(_)));

    if !is_valid_signature {
        return syn::Error::new(
            f.sig.span(),
            "the #[entry] function must have `fn() -> !` signature\n#[entry]函数必须使用`fn() -> !`签名",
        )
        .to_compile_error()
        .into();
    }

    // 导出为 "main" 符号
    f.attrs.push(parse_quote!(#[unsafe(export_name = "main")]));
    quote!( #f ).into()
}
