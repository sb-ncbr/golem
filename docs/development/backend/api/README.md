# Api
The api module contains FastAPI routes (request handlers), middleware and Pydantic response/request schemas.

For versioning, we use the `v1` prefix in the API path to indicate version 1 of the API. This way, we can easily add new versions in the future without breaking existing clients.

## Authorization

Authorization is handled using OAuth2 with Bearer token. The `OAuth2PasswordBearerWithCookie` class is used to extract the token from a cookie named `access_token`.

The `get_current_user` function is used to retrieve the current authenticated user from the token. If the user is not authenticated, an HTTP 401 Unauthorized error will be returned. If you want to allow unauthenticated access to a specific endpoint, you can use `get_current_user_optional` instead.

### Example
```python
@router.get("/required")
def example_required(
    user: User = Depends(get_current_user)
) -> ResponseSingle[str]:

    # will fail if not authenticated
    return ResponseSingle[str](data=f"Hello, {user.username}!")

@router.get("/optional")
def example_optional(
    user: User | None = Depends(get_current_user_optional)
) -> ResponseSingle[str]:

    # user will be None if not authenticated
    return ResponseSingle[str](data=f"Hello, {user?.username or 'Guest'}!")

```

## Routes

Each route corresponds to an HTTP endpoint and has a corresponding handler function that processes the request and returns a response. Each route returning a JSON response, should use either `ResponseSingle[T]` or `ResponseList[T]` for consistency. `ResponseError` is handled automatically by the `exception` middleware.

## Middleware

You can use middleware to intercept requests before they reach the route handler. This is useful for tasks like authentication, logging, or modifying request data.

## Schemas

Schemas contain request and response Pydantic models that define the structure of incoming and outgoing data.