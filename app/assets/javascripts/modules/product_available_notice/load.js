//= require modules/product_available_notice/product_available_notice_email_submitter
//= require modules/product_available_notice/product_available_notice_success_message_displayer
//= require modules/product_available_notice/product_available_notice_error_message_displayer

new ProductAvailableNoticeEmailSubmitter().config();
new ProductAvailableNoticeSuccessMessageDisplayer().config();
new ProductAvailableNoticeErrorMessageDisplayer().config();