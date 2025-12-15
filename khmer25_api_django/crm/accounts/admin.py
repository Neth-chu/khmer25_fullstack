from django.contrib import admin
from .models import (
    Category,
    Product,
    User,
    Cart,
    Order,
    OrderItem,
    Supplier,
    Banner,
)

# Register models
admin.site.register(Category)
admin.site.register(Product)
admin.site.register(User)
admin.site.register(Cart)
admin.site.register(Order)
admin.site.register(OrderItem)
admin.site.register(Supplier)
admin.site.register(Banner)
