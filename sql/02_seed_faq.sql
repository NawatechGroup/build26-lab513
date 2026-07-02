/* ===========================================================================
   LAB513 - 02_seed_faq.sql
   Seeds dbo.FAQ_Content with sample customer-support FAQ rows.
   Themes match the questions referenced in the lab (order tracking,
   damaged item, wrong item, returns, refunds, etc.).
   Idempotent: clears existing rows first.

   IMPORTANT (Exercise 1, Task 6): no question may contain the literal phrase
   "delivery status". That task proves keyword search
       WHERE question LIKE '%delivery status%'   -> returns 0 rows
   while semantic search for "Where can I check my delivery status?" still
   finds "How do I track my order?". Do not add a question with that phrase.
   =========================================================================== */

DELETE FROM dbo.FAQ_Embeddings;
DELETE FROM dbo.FAQ_Content;
GO

INSERT INTO dbo.FAQ_Content (faq_id, category, question, answer) VALUES
(1,  N'Orders',   N'How do I track my order?',
    N'You can track your order from the Orders page in your account. Select the order to see its current status and the latest tracking updates.'),
(2,  N'Orders',   N'Will I get an order confirmation?',
    N'Yes. After you place an order, we send an order confirmation email with your order number and a summary of your purchase.'),
(3,  N'Orders',   N'Can I change my delivery address after ordering?',
    N'You can update the delivery address from the order details page while the order is still Processing. Once it ships, the address can no longer be changed.'),
(4,  N'Orders',   N'How do I cancel an order?',
    N'You can cancel an order from the order details page while it is still Processing. After it ships, please start a return instead.'),
(5,  N'Returns',  N'How do I return a damaged item?',
    N'If your item arrived damaged, open the order, select Return, and choose Damaged as the reason. We will send a prepaid shipping label and arrange a replacement or refund.'),
(6,  N'Returns',  N'What if I received the wrong item?',
    N'If you received the wrong item, start a return from the order and select Wrong item received. We will ship the correct item and cover the return postage.'),
(7,  N'Returns',  N'What is your return policy?',
    N'Most items can be returned within 30 days of delivery in their original condition. Some categories such as final-sale items are not eligible.'),
(8,  N'Returns',  N'How long do refunds take?',
    N'Refunds are issued to your original payment method within 5 to 7 business days after we receive and inspect the returned item.'),
(9,  N'Shipping', N'How much does shipping cost?',
    N'Standard shipping is free on orders over 50. Orders below that amount have a flat standard shipping fee shown at checkout.'),
(10, N'Shipping', N'Do you ship internationally?',
    N'We ship to most countries. Shipping cost and delivery time are calculated at checkout based on the destination.'),
(11, N'Payments', N'What payment methods do you accept?',
    N'We accept major credit and debit cards and most common digital wallets. The available options are shown at checkout.'),
(12, N'Payments', N'Why was my payment declined?',
    N'A payment can be declined due to an incorrect card number, insufficient funds, or a bank security hold. Verify your details or contact your bank, then try again.'),
(13, N'Account',  N'How do I reset my password?',
    N'Select Forgot password on the sign-in page and follow the emailed link to set a new password.'),
(14, N'Account',  N'How do I contact customer support?',
    N'You can reach customer support from the Help Center by starting a chat or submitting a request, and we will respond as soon as possible.'),
(15, N'Account', N'Can I change my email address?', N'Yes, you can update your email address in the Account Settings section under Profile. Please ensure you verify your new email address via the link sent to your inbox.'),
(16, N'Shipping', N'Can I track my package after it ships?', N'Yes, you will receive a tracking number via email once the carrier picks up your package. Use the link provided to view real-time location updates.'),
(17, N'Payments', N'Can I use multiple payment methods for one order?', N'Currently, we only support one payment method per order. You can choose your preferred credit card or digital wallet at checkout.'),
(18, N'Orders', N'Do you offer gift wrapping?', N'Yes, you can select the "Gift Wrap" option at checkout for a small additional fee. You can also include a personalized message to the recipient.'),
(19, N'Returns', N'Do I have to pay for return shipping?', N'For damaged or incorrect items, return shipping is free. For other returns, a flat return fee is deducted from your refund amount to cover processing.'),
(20, N'Account', N'Is my personal information secure?', N'Yes, we use industry-standard SSL encryption and secure payment gateways to ensure your personal and payment data remains protected and private.'),
(21, N'Shipping', N'What happens if my package is lost?', N'If your tracking has not updated for more than 5 days or the delivery window has passed, please contact our support team so we can open an investigation with the carrier.'),
(22, N'Payments', N'Can I request an invoice?', N'Yes, an electronic invoice is automatically attached to your order confirmation email. You can also download it anytime from the Order History page.'),
(23, N'Orders', N'Can I pre-order items?', N'Yes, selected items are available for pre-order. The expected shipping date is clearly displayed on the product page, and you will be charged once the item ships.'),
(24, N'General', N'What are your customer support operating hours?', N'Our support team is available 24/7 via chat and email to assist you with any questions or issues regarding your order.'),
(25, N'Account', N'How can I delete my account?',
N'You can request account deletion in the Account Settings menu. Please note that this action is permanent and will remove all your order history, preferences, and personal data.'),
(26, N'Products', N'How do I know if an item is back in stock?',
N'On the product page, you can select the "Notify Me" button to receive an automated email alert the moment the item becomes available again.'),
(27, N'Shipping', N'Do you offer express shipping?',
N'Yes, we offer expedited shipping options at checkout for an additional fee. The estimated delivery date for each shipping method is displayed before you complete your purchase.'),
(28, N'Payments', N'Can I save my payment details for future use?',
N'Yes, you can securely save your credit or debit card details in your account for faster checkout. We use encrypted storage and never keep your CVV code.'),
(29, N'Orders', N'What should I do if my order is significantly delayed?',
N'We apologize for any inconvenience. Please check your tracking link for updates. If the delivery is more than 3 business days past the estimated date, please contact our support team to investigate.'),
(30, N'Returns', N'How do I exchange an item for a different size or color?',
N'Currently, we handle exchanges as a return and a new order. Please return the original item for a refund and place a new order for the preferred size or color.'),
(31, N'General', N'How do I apply a discount code?',
N'You can enter your promo code in the "Discount Code" field at the final checkout screen. Make sure to click "Apply" before completing your payment.'),
(32, N'Account', N'Can I view my order history from previous years?',
N'Yes, your full order history is saved in your account under the "My Orders" tab. You can filter by date to view purchases made in previous years.'),
(33, N'Products', N'Do you have a size guide available?',
N'Yes, each product page features a Size Guide link above the size selector. It includes detailed measurements to help you find the best fit.'),
(34, N'General', N'Do you have a loyalty or rewards program?',
N'Yes! You can join our Loyalty Program to earn points on every purchase, which can be redeemed for discounts on future orders. Sign up in the Account section.'),
(35, N'Account', N'How do I unsubscribe from your newsletter?',
N'You can click the "Unsubscribe" link at the bottom of any promotional email, or update your notification preferences in the Account Settings menu.'),
(36, N'Shipping', N'Can you ship to a P.O. Box address?',
N'We ship to P.O. Boxes via standard shipping options. Please ensure your shipping address is entered correctly to avoid any delivery delays.'),
(37, N'Payments', N'Can I pay using a gift card?',
N'Yes, you can use our store-issued gift cards. Simply enter the gift card code in the "Gift Card" field at the checkout stage.'),
(38, N'Returns', N'Can I return part of a bundle or set?',
N'Items purchased as part of a set must generally be returned as a complete set. Please check the product description for specific rules regarding bundle returns.'),
(39, N'General', N'How do I report a technical issue with the website?',
N'If you encounter a bug or website error, please contact our support team with a screenshot and a brief description of the issue so our tech team can investigate.'),
(40, N'Account', N'How do I request a copy of my personal data?',
N'Under our Privacy Policy, you can request an export of your personal data by contacting our Privacy Team through the Help Center. We will process your request within 30 days.');
GO

SELECT COUNT(*) AS faq_count FROM dbo.FAQ_Content;
GO
