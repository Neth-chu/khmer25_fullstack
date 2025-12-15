from rest_framework import viewsets
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework import status
from django.contrib.auth.hashers import check_password
import secrets
from .models import (
    Category, Product, User, Cart, Order, OrderItem,
    Supplier, AuthToken, Banner
)
from .serializers import (
    CategorySerializer, ProductSerializer, UserSerializer, UserPublicSerializer, CartSerializer, 
    OrderSerializer, OrderItemSerializer, SupplierSerializer,BannerSerializer,
)
from .authentication import AuthTokenAuthentication

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    parser_classes = [MultiPartParser, FormParser]
    authentication_classes = [AuthTokenAuthentication]
    permission_classes = [IsAuthenticatedOrReadOnly]

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class CartViewSet(viewsets.ModelViewSet):
    queryset = Cart.objects.all()
    serializer_class = CartSerializer
    permission_classes = [AllowAny]      # <--- IMPORTANT


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer

class OrderItemViewSet(viewsets.ModelViewSet):
    queryset = OrderItem.objects.all()
    serializer_class = OrderItemSerializer







class BannerViewSet(viewsets.ModelViewSet):
    queryset = Banner.objects.all()
    serializer_class = BannerSerializer
    parser_classes = [MultiPartParser, FormParser]





class SupplierViewSet(viewsets.ModelViewSet):
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer

@api_view(["POST"])
def register_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token = issue_token(user)
        return Response(
            {
                "message": "User created successfully",
                "user": UserPublicSerializer(user).data,
                "token": token.key,
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
def login_user(request):
    phone = request.data.get("phone")
    password = request.data.get("password")

    if not phone or not password:
        return Response(
            {"detail": "Phone and password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response(
            {"detail": "Invalid phone or password."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not check_password(password, user.password):
        return Response(
            {"detail": "Invalid phone or password."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    token = issue_token(user, replace_existing=True)
    return Response(
        {
            "message": "Login successful",
            "user": UserPublicSerializer(user).data,
            "token": token.key,
        },
        status=status.HTTP_200_OK,
    )


@api_view(["GET"])
def get_user_info(request, pk=None):
    """
    Fetch a user by id or phone.
    Accepts:
    - query params: ?id=<user_id> or ?phone=<phone_number>
    - URL path: /api/user/<id>/
    """
    user_id = request.query_params.get("id") or pk
    phone = request.query_params.get("phone")

    if not user_id and not phone:
        return Response(
            {"detail": "Provide 'id' or 'phone' to fetch user info."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        if user_id:
            user = User.objects.get(pk=user_id)
        else:
            user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response(
            {"detail": "User not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    return Response(UserPublicSerializer(user).data, status=status.HTTP_200_OK)


def issue_token(user, replace_existing=False):
    """
    Create a new token for the given user.
    If replace_existing=True, old tokens are removed first.
    """
    if replace_existing:
        AuthToken.objects.filter(user=user).delete()
    token = AuthToken.objects.create(user=user, key=secrets.token_hex(20))
    return token
