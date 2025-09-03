#[macro_export]
macro_rules! with_client {
    ($self:ident, $block:block ) => {{
        $self.tokio_runtime
            .handle()
            .spawn(async move { $block })
            .await
            .map_err(|err| FilenClientError::FilenClientError {
                msg: format!("{}", err),
            })
    }};
}
