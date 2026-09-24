const authorize = (...allowedRoles) => (req, res, next) => {
  if (!req.user || !allowedRoles.includes(req.user.role)) {
    const error = new Error('You do not have permission to access this resource.');
    error.statusCode = 403;
    error.code = 'FORBIDDEN';
    return next(error);
  }

  return next();
};

module.exports = authorize;